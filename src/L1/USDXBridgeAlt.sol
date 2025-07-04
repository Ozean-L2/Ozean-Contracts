// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin/contracts/security/ReentrancyGuard.sol";
import {
    SendParam, OFTReceipt, MessagingReceipt, MessagingFee
} from "@layerzero/oapp/contracts/oft/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzero/oapp/contracts/oapp/libs/OptionsBuilder.sol";
import {IERC20Decimals} from "src/L1/interfaces/IERC20Decimals.sol";
import {IUSDX} from "src/L1/interfaces/IUSDX.sol";

/// @title  USDX Bridge Alt
/// @notice This contract provides bridging functionality for allow-listed stablecoins to the Ozean Layer L2.
///         Users can deposit any allow-listed stablecoin and receive USDX, the native gas token for Ozean, on
///         the L2 via the LayerZeroV2. The owner of this contract can modify the set of
///         allow-listed stablecoins accepted, along with the deposit caps, and can also withdraw any deposited
///         ERC20 tokens.
/// @dev    !!! USED TO TEST LAYER ZERO BRIDGING - NOT FOR MAINNET - NEEDS AN AUDIT !!!
contract USDXBridgeAlt is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Decimals;
    using OptionsBuilder for bytes;

    // Custom Errors
    error ZeroAddress();
    error ZeroAmount();
    error StablecoinNotAccepted();
    error BridgeAmountTooSmall();
    error ExceedsDepositCap();
    error FeeOnTransferTokenNotSupported();
    error InsufficientLayerZeroFee();
    error ETHRefundFailed();
    error InsufficientETHBalance();
    error ETHTransferFailed();
    error GasLimitMustBePositive();
    error InvalidArrayLength();
    error InvalidMinAmount();

    /// @notice The address of the USDX contract on mainnet.
    IUSDX public immutable l1USDX;

    /// @notice The EID of the Ozean L2.
    uint32 public immutable eid;

    /// @notice Addresses of allow-listed stablecoins.
    /// @dev    stablecoin => allowlisted
    mapping(address => bool) public allowlisted;

    /// @notice The limit to the total USDX supply that can be minted and bridged per deposited stablecoin.
    /// @dev    stablecoin => amount
    mapping(address => uint256) public depositCap;

    /// @notice The total amount of USDX bridged via this contract per deposited stablecoin.
    /// @dev    stablecoin => amount
    mapping(address => uint256) public totalBridged;

    /// @notice The gas limit for lzReceive execution on the destination chain.
    /// @dev    Default value is 65000.
    uint128 public lzReceiveGasLimit;

    /// EVENTS ///

    /// @notice An event emitted when a bridge deposit is made by a user.
    event BridgeDeposit(address indexed _stablecoin, uint256 _amount, uint256 _minAmount, address indexed _to, bytes32 _messageId);

    /// @notice Emitted when ETH is withdrawn from the contract.
    /// @param amount The amount of ETH withdrawn.
    /// @param to The recipient address.
    event WithdrawETH(uint256 amount, address indexed to);

    /// @notice Emitted when an ERC20 token is withdrawn from the contract.
    /// @param token The ERC20 token address.
    /// @param amount The amount withdrawn.
    /// @param to The recipient address.
    event WithdrawERC20(address indexed token, uint256 amount, address indexed to);

    /// @notice An event emitted when an ERC20 stablecoin is set as allowlisted or not (true if allowlisted, false if
    /// removed).
    event AllowlistSet(address indexed _coin, bool _set);

    /// @notice An event emitted when the deposit cap for an ERC20 stablecoin is modified.
    event DepositCapSet(address indexed _coin, uint256 _newDepositCap);

    /// @notice An event emitted when the lzReceive gas limit is updated.
    /// @param _oldGasLimit The previous gas limit value.
    /// @param _newGasLimit The new gas limit value.
    event LzReceiveGasLimitUpdated(uint128 _oldGasLimit, uint128 _newGasLimit);

    /// SETUP ///

    /// @notice The constructor contract set up.
    /// @param  _owner The address granted ownership rights to this contract.
    /// @param  _l1USDX The address for the USDX token on Ethereum mainnet.
    /// @param  _eid The endpoint id for the Layer Zero transfer.
    /// @param  _stablecoins An array of allow-listed stablecoins that can be used to mint and bridge USDX.
    /// @param  _depositCaps The deposit caps per stablecoin for this contract, which limits the total amount bridged.
    /// @dev    Ensure that the index for each deposit cap aligns with the index of the stablecoin that is allowlisted.
    /// @dev    This function includes an unbounded for-loop. Ensure that the array of allow-listed
    ///         stablecoins is reasonable in length.
    constructor(
        address _owner,
        address _l1USDX,
        uint32 _eid,
        address[] memory _stablecoins,
        uint256[] memory _depositCaps
    ) {
        _transferOwnership(_owner);
        l1USDX = IUSDX(_l1USDX);
        eid = _eid;
        lzReceiveGasLimit = 65000;
        uint256 length = _stablecoins.length;
        if (_stablecoins.length != _depositCaps.length) {
            revert InvalidArrayLength();
        }
        for (uint256 i; i < length; ++i) {
            if (_stablecoins[i] == address(0)) revert ZeroAddress();
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
    /// @param  _minAmount The minimum amount of USDX to be received after bridging, used for slippage protection.
    /// @param  _to Receiving address on L2.
    function bridge(address _stablecoin, uint256 _amount, uint256 _minAmount, address _to) external payable nonReentrant {
        /// Checks
        if (_amount == 0) revert ZeroAmount();
        if (_to == address(0)) revert ZeroAddress();
        if (!allowlisted[_stablecoin]) revert StablecoinNotAccepted();
        uint256 bridgeAmount = getBridgeAmount(_stablecoin, _amount);
        if (bridgeAmount == 0) revert BridgeAmountTooSmall();
        if (_minAmount > bridgeAmount) revert InvalidMinAmount();
        if (totalBridged[_stablecoin] + _amount > depositCap[_stablecoin]) {
            revert ExceedsDepositCap();
        }
        /// Update state
        uint256 balanceBefore = IERC20Decimals(_stablecoin).balanceOf(address(this));
        IERC20Decimals(_stablecoin).safeTransferFrom(msg.sender, address(this), _amount);
        if (IERC20Decimals(_stablecoin).balanceOf(address(this)) - balanceBefore != _amount) {
            revert FeeOnTransferTokenNotSupported();
        }
        totalBridged[_stablecoin] += _amount;
        // Mint USDX
        l1USDX.mint(address(this), bridgeAmount);
        /// Bridge USDX via LZ
        bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(lzReceiveGasLimit, 0);
        SendParam memory sendParam =
            SendParam(eid, addressToBytes32(_to), bridgeAmount, _minAmount, extraOptions, "", "");
        MessagingFee memory fee = l1USDX.quoteSend(sendParam, false);
        if (msg.value < fee.nativeFee) revert InsufficientLayerZeroFee();
        (MessagingReceipt memory msgReceipt,) =
                 l1USDX.send{value: fee.nativeFee}(sendParam, fee, msg.sender);
        /// Refund excess eth if any
        uint256 excessEth = msg.value - fee.nativeFee;
        if (excessEth > 0) {
            (bool success,) = address(msg.sender).call{value: excessEth}("");
            if (!success) revert ETHRefundFailed();
        }
        /// @dev some check to ensure tokens are sent in case of soft-revert at the bridge
        emit BridgeDeposit(_stablecoin, _amount, _minAmount, _to, msgReceipt.guid);
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
    /// @param  _newDepositCap The new deposit cap in the native decimals of the stablecoin.
    function setDepositCap(address _stablecoin, uint256 _newDepositCap) external onlyOwner {
        depositCap[_stablecoin] = _newDepositCap;
        emit DepositCapSet(_stablecoin, _newDepositCap);
    }

    /// @notice This function allows the owner to withdraw ETH held by this contract.
    /// @param  _amount The amount of ETH to withdraw.
    /// @param  _to The address to receive the withdrawn ETH.
    function withdrawETH(uint256 _amount, address _to) external onlyOwner {
        if (_amount == 0) revert ZeroAmount();
        if (_to == address(0)) revert ZeroAddress();
        if (_amount > address(this).balance) revert InsufficientETHBalance();
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) revert ETHTransferFailed();
        emit WithdrawETH(_amount, _to);
    }

    /// @notice This function allows the owner to withdraw any ERC20 token held by this contract.
    /// @param  _coin The address of the ERC20 token to withdraw.
    /// @param  _amount The amount of tokens to withdraw.
    function withdrawERC20(address _coin, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert ZeroAmount();
        IERC20Decimals(_coin).safeTransfer(msg.sender, _amount);
        emit WithdrawERC20(_coin, _amount, msg.sender);
    }

    /// VIEW ///

    /// @notice This view function normalises deposited amounts given diverging decimals for tokens and USDX.
    /// @param  _stablecoin The address of the deposited stablecoin.
    /// @param  _amount The amount of the stablecoin deposited.
    /// @return uint256 The amount of USDX to mint given the deposited stablecoin amount.
    /// @dev    Assumes 1:1 conversion between the deposited stablecoin and USDX.
    function getBridgeAmount(address _stablecoin, uint256 _amount) public view returns (uint256) {
        uint8 depositDecimals = IERC20Decimals(_stablecoin).decimals();
        uint8 usdxDecimals = l1USDX.decimals();

        if (usdxDecimals == depositDecimals) {
            return _amount;
        } else if (usdxDecimals > depositDecimals) {
            return _amount * (10 ** (usdxDecimals - depositDecimals));
        } else {
            return _amount / (10 ** (depositDecimals - usdxDecimals));
        }
    }

    /// @notice Updates the gas limit for lzReceive execution on the destination chain.
    /// @dev    Only callable by the contract owner.
    /// @param  _newGasLimit The new gas limit value to set.
    function setLzReceiveGasLimit(uint128 _newGasLimit) external onlyOwner {
        if (_newGasLimit == 0) revert GasLimitMustBePositive();
        uint128 oldGasLimit = lzReceiveGasLimit;
        lzReceiveGasLimit = _newGasLimit;
        emit LzReceiveGasLimitUpdated(oldGasLimit, _newGasLimit);
    }

    /// @notice Converts an Ethereum address to a bytes32 representation.
    /// @param  _addr The Ethereum address to convert.
    /// @return bytes32 The bytes32 representation of the address.
    /// @dev    This function truncates the address to its lower 20 bytes and right-aligns it within the bytes32.
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
