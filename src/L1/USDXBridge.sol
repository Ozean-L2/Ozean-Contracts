// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin/contracts/security/ReentrancyGuard.sol";
import {
    SendParam, OFTReceipt, MessagingReceipt, MessagingFee
} from "@layerzero/oapp/contracts/oft/interfaces/IOFT.sol";
import {MessagingFee} from "@layerzero/oapp/contracts/oapp/OApp.sol";
import {IERC20Decimals} from "src/L1/interfaces/IERC20Decimals.sol";
import {IUSDX} from "src/L1/interfaces/IUSDX.sol";
import { IL1StandardBridge } from "src/L1/interfaces/IL1StandardBridge.sol";

/// @title  USDX Bridge
/// @notice This contract provides bridging functionality for allow-listed stablecoins to the Ozean Layer L2.
///         Users can deposit any allow-listed stablecoin and recieve USDX, the native gas token for Ozean, on
///         the L2 via the Optimism Portal contract. The owner of this contract can modify the set of
///         allow-listed stablecoins accepted, along with the deposit caps, and can also withdraw any deposited
///         ERC20 tokens.
/// @dev    !!! NEEDS AN AUDIT !!!
contract USDXBridge is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Decimals;
    
    IL1StandardBridge public immutable standardBridge;

    /// @notice The address of the USDX contract on mainnet.
    IUSDX public immutable l1USDX;

    address public immutable l2USDX;

    /// @notice Addresses of allow-listed stablecoins.
    /// @dev    stablecoin => allowlisted
    mapping(address => bool) public allowlisted;

    /// @notice The limit to the total USDX supply that can be minted and bridged per deposted stablecoin.
    /// @dev    stablecoin => amount
    mapping(address => uint256) public depositCap;

    /// @notice The total amount of USDX bridged via this contract per deposted stablecoin.
    /// @dev    stablecoin => amount
    mapping(address => uint256) public totalBridged;

    /// @notice The gas limit passed to the Optimism portal when depositing USDX.
    uint32 public gasLimit;

    /// EVENTS ///

    /// @notice An event emitted when a bridge deposit is made by a user.
    event BridgeDeposit(address indexed _stablecoin, uint256 _amount, address indexed _from, address indexed _to);

    /// @notice An event emitted when an ERC20 token is withdrawn from this contract.
    event WithdrawCoins(address indexed _coin, uint256 _amount, address indexed _to);

    /// @notice An event emitted when en ERC20 stablecoin is set as allowlisted or not (true if allowlisted, false if
    /// removed).
    event AllowlistSet(address indexed _coin, bool _set);

    /// @notice An event emitted when the deposit cap for an ERC20 stablecoin is modified.
    event DepositCapSet(address indexed _coin, uint256 _newDepositCap);

    /// SETUP ///

    /// @notice The constructor contract set up.
    /// @param  _owner The address granted ownership rights to this contract.
    /// @param  _l1USDX The address for the USDX token on Ethereum mainnet.
    /// @param  _l2USDX The address for the USDX token on Ozean mainnet.
    /// @param  _standardBridge The address of the standard bridge contract.
    /// @param  _stablecoins An array of allow-listed stablecoins that can be used to mint and bridge USDX.
    /// @param  _depositCaps The deposit caps per stablecoin for this contract, which limits the total amount bridged.
    /// @dev    Ensure that the index for each deposit cap aligns with the index of the stablecoin that is allowlisted.
    /// @dev    This function includes an unbounded for-loop. Ensure that the array of allow-listed
    ///         stablecoins is reasonable in length.
    constructor(
        address _owner,
        address _l1USDX,
        address _l2USDX,
        address _standardBridge,
        address[] memory _stablecoins,
        uint256[] memory _depositCaps
    ) {
        _transferOwnership(_owner);
        l1USDX = IUSDX(_l1USDX);
        l2USDX = _l2USDX;
        standardBridge = IL1StandardBridge(_standardBridge);
        gasLimit = 21000;
        uint256 length = _stablecoins.length;
        require(
            length == _depositCaps.length,
            "USDX Bridge: Stablecoins array length must equal the Deposit Caps array length."
        );
        for (uint256 i; i < length; ++i) {
            require(_stablecoins[i] != address(0), "USDX Bridge: Zero address.");
            allowlisted[_stablecoins[i]] = true;
            emit AllowlistSet(_stablecoins[i], true);
            depositCap[_stablecoins[i]] = _depositCaps[i];
            emit DepositCapSet(_stablecoins[i], _depositCaps[i]);
        }
    }

    /// BRIDGE ///

    /// @notice This function allows users to deposit any allow-listed stablecoin to the Ozean Layer L2.
    /// @param  _stablecoin Depositing stablecoin address.
    /// @param  _amount The amount of deposit stablecoin to be swapped for USDX.
    /// @param  _to Recieving address on L2.
    /// @param  _extraData Optional data to forward to L2.
    function bridge(
        address _stablecoin, 
        uint256 _amount, 
        address _to,
        bytes calldata _extraData
    ) external nonReentrant {
        /// Checks
        require(allowlisted[_stablecoin], "USDX Bridge: Stablecoin not accepted.");
        require(_amount > 0, "USDX Bridge: May not bridge nothing.");
        uint256 bridgeAmount = _getBridgeAmount(_stablecoin, _amount);
        require(
            totalBridged[_stablecoin] + bridgeAmount <= depositCap[_stablecoin],
            "USDX Bridge: Bridge amount exceeds deposit cap."
        );
        /// Update state
        uint256 balanceBefore = IERC20Decimals(_stablecoin).balanceOf(address(this));
        IERC20Decimals(_stablecoin).safeTransferFrom(msg.sender, address(this), _amount);
        require(
            IERC20Decimals(_stablecoin).balanceOf(address(this)) - balanceBefore == _amount,
            "USDX Bridge: Fee-on-transfer tokens not supported."
        );
        totalBridged[_stablecoin] += bridgeAmount;
        /// Mint USDX
        l1USDX.mint(address(this), bridgeAmount);
        /// Bridge USDX
        l1USDX.approve(address(standardBridge), bridgeAmount);
        standardBridge.depositERC20To(address(l1USDX), l2USDX, _to, bridgeAmount, gasLimit, _extraData);
        /// @dev some check to ensure tokens are sent in case of soft-revert at the bridge
        emit BridgeDeposit(_stablecoin, _amount, msg.sender, _to);
    }

    /// OWNER ///

    /// @notice This function allows the owner to either add or remove an allow-listed stablecoin for bridging.
    /// @param  _stablecoin The stablecoin address to add or remove.
    /// @param  _set A boolean for whether the stablecoin is allow-listed or not. True for allow-listed, false
    ///         otherwise.
    function setAllowlist(address _stablecoin, bool _set) external onlyOwner {
        allowlisted[_stablecoin] = _set;
        emit AllowlistSet(_stablecoin, _set);
    }

    /// @notice This function allows the owner to modify the deposit cap for deposited stablecoins.
    /// @param  _stablecoin The stablecoin address to modify the deposit cap.
    /// @param  _newDepositCap The new deposit cap.
    function setDepositCap(address _stablecoin, uint256 _newDepositCap) external onlyOwner {
        depositCap[_stablecoin] = _newDepositCap;
        emit DepositCapSet(_stablecoin, _newDepositCap);
    }

    /// @notice This function allows the owner to withdraw any ERC20 token held by this contract.
    /// @param  _coin The address of the ERC20 token to withdraw.
    /// @param  _amount The amount of tokens to withdraw.
    function withdrawERC20(address _coin, uint256 _amount) external onlyOwner {
        IERC20Decimals(_coin).safeTransfer(msg.sender, _amount);
        emit WithdrawCoins(_coin, _amount, msg.sender);
    }

    /// VIEW ///

    /// @notice This view function normalises deposited amounts given diverging decimals for tokens and USDX.
    /// @param  _stablecoin The address of the deposited stablecoin.
    /// @param  _amount The amount of the stablecoin deposited.
    /// @return uint256 The amount of USDX to mint given the deposited stablecoin amount.
    /// @dev    Assumes 1:1 conversion between the deposited stablecoin and USDX.
    function _getBridgeAmount(address _stablecoin, uint256 _amount) internal view returns (uint256) {
        uint8 depositDecimals = IERC20Decimals(_stablecoin).decimals();
        uint8 usdxDecimals = l1USDX.decimals();
        return (_amount * 10 ** usdxDecimals) / (10 ** depositDecimals);
    }
}
