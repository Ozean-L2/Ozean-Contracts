// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ILGEMigration} from "src/L1/interfaces/ILGEMigration.sol";
import {IL1StandardBridge} from "src/L1/interfaces/IL1StandardBridge.sol";
import {IL1LidoTokensBridge} from "src/L1/interfaces/IL1LidoTokensBridge.sol";
import {IUSDXBridge} from "src/L1/interfaces/IUSDXBridge.sol";

/// @title  LGE Migration V1
/// @notice This contract facilitates the migration of staked tokens from the LGE Staking pool
///         on Layer 1 to the Ozean Layer 2.
/// @dev    !!! DEPRECATED !!!
///         This contract needs to be updated to handle the new bridge paths, DO NOT DEPLOY WITHOUT UPGRADING
contract LGEMigrationV1 is Ownable, ILGEMigration, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The standard bridge contract for Layer 1 to Layer 2 transfers.
    IL1StandardBridge public immutable l1StandardBridge;

    /// @notice The L1 lido bridge contract.
    IL1LidoTokensBridge public immutable l1LidoTokensBridge;

    /// @notice The L1 USDX bridge that converts USDC into USDX.
    IUSDXBridge public immutable usdxBridge;

    /// @notice The address of the LGE Staking contract.
    address public immutable lgeStaking;

    /// @notice The address of Circle's USDC.
    address public immutable usdc;

    /// @notice The address of Wrapped Staked Ether.
    address public immutable wstETH;

    /// @notice A mapping from Layer 1 token addresses to their corresponding Layer 2 addresses.
    mapping(address => address) public l1ToL2Addresses;

    /// @notice A mapping that identifies invalid L2 migration address recipients.
    mapping(address => bool) public restrictedL2Addresses;

    /// @notice A mapping from Layer 1 token address to the gas limits passed to the bridge contracts.
    mapping(address => uint32) public gasLimits;

    constructor(
        address _owner,
        address _l1StandardBridge,
        address _l1LidoTokensBridge,
        address _usdxBridge,
        address _lgeStaking,
        address _usdc,
        address _wstETH,
        address[] memory _l1Addresses,
        address[] memory _l2Addresses,
        address[] memory _restrictedL2Addresses
    ) {
        _transferOwnership(_owner);
        l1StandardBridge = IL1StandardBridge(_l1StandardBridge);
        l1LidoTokensBridge = IL1LidoTokensBridge(_l1LidoTokensBridge);
        usdxBridge = IUSDXBridge(_usdxBridge);
        lgeStaking = _lgeStaking;
        usdc = _usdc;
        wstETH = _wstETH;
        uint256 length = _l1Addresses.length;
        require(
            length == _l2Addresses.length,
            "LGE Migration: L1 addresses array length must equal the L2 addresses array length."
        );
        for (uint256 i; i < length; ++i) {
            l1ToL2Addresses[_l1Addresses[i]] = _l2Addresses[i];
            gasLimits[_l1Addresses[i]] = 21000;
        }
        length = _restrictedL2Addresses.length;
        for (uint256 j; j < length; ++j) {
            restrictedL2Addresses[_restrictedL2Addresses[j]] = true;
        }
    }

    /// @notice This function is called by the LGE Staking contract to facilitate migration of staked tokens from
    ///         the LGE Staking pool to the Ozean L2.
    /// @param _l2Destination The address which will be credited the tokens on Ozean.
    /// @param _tokens The tokens being migrated to Ozean from the LGE Staking contract.
    /// @param _amounts The amounts of each token to be migrated to Ozean for the _user
    function migrate(address _l2Destination, address[] calldata _tokens, uint256[] calldata _amounts)
        external
        nonReentrant
    {
        require(msg.sender == lgeStaking, "LGE Migration: Only the staking contract can call this function.");
        require(!restrictedL2Addresses[_l2Destination], "LGE Migration: L2 address recipient restricted.");
        uint256 length = _tokens.length;
        for (uint256 i; i < length; i++) {
            require(l1ToL2Addresses[_tokens[i]] != address(0), "LGE Migration: L2 address not set for migration.");
            if (_tokens[i] == usdc) {
                /// Handle USDC
                IERC20(_tokens[i]).safeApprove(address(usdxBridge), _amounts[i]);
                usdxBridge.bridge(_tokens[i], _amounts[i], _l2Destination);
            } else if (_tokens[i] == wstETH) {
                /// Handle wstETH
                IERC20(_tokens[i]).safeApprove(address(l1LidoTokensBridge), _amounts[i]);
                l1LidoTokensBridge.depositERC20To(
                    _tokens[i], l1ToL2Addresses[_tokens[i]], _l2Destination, _amounts[i], gasLimits[_tokens[i]], ""
                );
            } else {
                /// Handle other tokens
                IERC20(_tokens[i]).safeApprove(address(l1StandardBridge), _amounts[i]);
                l1StandardBridge.depositERC20To(
                    _tokens[i], l1ToL2Addresses[_tokens[i]], _l2Destination, _amounts[i], gasLimits[_tokens[i]], ""
                );
            }
        }
    }

    /// @notice This function allows the contract owner to recover ERC20 tokens from the contract.
    /// @param  _token The address of the ERC20 token to recover.
    /// @param  _amount The amount of tokens to transfer to the recipient.
    /// @param  _recipient The address that will receive the recovered tokens.
    function recoverTokens(address _token, uint256 _amount, address _recipient) external onlyOwner nonReentrant {
        IERC20(_token).transfer(_recipient, _amount);
    }

    /// @notice This function allows the contract owner to change the gas limit passed to the bridging contracts.
    /// @param  _token The address of the ERC20 token.
    /// @param  _limit The new gas limit for bridging the token.
    function setGasLimit(address _token, uint32 _limit) external onlyOwner {
        gasLimits[_token] = _limit;
    }
}
