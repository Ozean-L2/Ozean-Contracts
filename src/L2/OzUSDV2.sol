// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC4626, ERC20, IERC20Metadata, SafeERC20} from "openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ReentrancyGuard} from "openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "openzeppelin/contracts/access/AccessControl.sol";

/// @title  Ozean USD (ozUSD) Token Contract
/// @notice This contract represents a yield-bearing vault for USDX tokens, adhering to the ERC-4626 standard.
/// @dev    !!! NEEDS AN AUDIT !!!
///         Overrides _deposit() and _withdraw() flow to allow only the owner to distribute yield.
///         https://docs.euler.finance/creator-tools/security/attack-vectors/donation-attacks/
contract OzUSDV2 is ERC4626, ReentrancyGuard, Pausable, Ownable, AccessControl {
    using SafeERC20 for IERC20Metadata;

    // Custom Errors
    error InsufficientInitialShares();
    error ZeroAmount();

    /// @notice Role for accounts authorized to distribute yield
    bytes32 public constant YIELD_DISTRIBUTOR_ROLE = keccak256("YIELD_DISTRIBUTOR_ROLE");

    /// @notice The total number of USDX held by this contract that has been deposited legitmately.
    uint256 public totalDeposited;

    /// @notice An event for distribution of yield (in the form of USDX) to all participants.
    /// @param  _previousTotalBalance The total amount of USDX held by the contract before rebasing.
    /// @param  _newTotalBalance The total amount of USDX held by the contract after rebasing.
    event YieldDistributed(uint256 _previousTotalBalance, uint256 _newTotalBalance);

    /// @notice Constructor to initialize the ozUSD vault.
    /// @param  _usdx The address of the USDX token (the underlying asset).
    /// @param  _owner The address of the contract owner.
    /// @param  _sharesAmount The initial amount of ozUSD shares to mint.
    constructor(IERC20Metadata _usdx, address _owner, uint256 _sharesAmount)
        ERC4626(_usdx)
        ERC20("Ozean USD", "ozUSD")
    {
        _transferOwnership(_owner);
        if (_sharesAmount < 1e18) revert InsufficientInitialShares();
        mint(_sharesAmount, address(0xdead));
        
        // Set up initial role structure
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    /// OVERRIDES ///

    /// @notice Deposits USDX into the vault and mints ozUSD shares to the receiver.
    /// @param _assets The amount of USDX to deposit.
    /// @param _receiver The address receiving ozUSD shares.
    /// @return shares The number of ozUSD shares minted.
    function deposit(uint256 _assets, address _receiver)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        shares = super.deposit(_assets, _receiver);
    }

    /// @notice Mints a specified amount of ozUSD shares by depositing the necessary amount of USDX.
    /// @param _shares The amount of ozUSD shares to mint.
    /// @param _receiver The address receiving the ozUSD shares.
    /// @return assets The amount of USDX deposited.
    function mint(uint256 _shares, address _receiver)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 assets)
    {
        assets = super.mint(_shares, _receiver);
    }

    /// @dev See {IERC4626-totalAssets}.
    /// @notice Returns the total amount of USDX in the vault, including both user deposits and distributed yield.
    /// @return The total amount of assets in the vault.
    function totalAssets() public view override returns (uint256) {
        return totalDeposited;
    }

    /// @dev See {IERC4626-_deposit}.
    /// @notice Internal hook for handling deposit logic and updating totalDeposited.
    /// @param _caller The address initiating the deposit.
    /// @param _receiver The address receiving the ozUSD shares.
    /// @param _assets The amount of USDX deposited.
    /// @param _shares The number of ozUSD shares minted.
    function _deposit(address _caller, address _receiver, uint256 _assets, uint256 _shares) internal override {
        super._deposit(_caller, _receiver, _assets, _shares);
        totalDeposited += _assets;
    }

    /// @dev See {IERC4626-_withdraw}.
    /// @notice Internal hook for handling withdrawal logic and updating totalDeposited.
    /// @param _caller The address initiating the withdrawal.
    /// @param _receiver The address receiving the USDX.
    /// @param _owner The address that owns the ozUSD shares.
    /// @param _assets The amount of USDX withdrawn.
    /// @param _shares The number of ozUSD shares burned.
    function _withdraw(address _caller, address _receiver, address _owner, uint256 _assets, uint256 _shares)
        internal
        override
    {
        totalDeposited -= _assets;
        super._withdraw(_caller, _receiver, _owner, _assets, _shares);
    }

    /// OWNER ///

    /// @notice Distributes the yield to the protocol by updating the total pooled USDX balance.
    /// @param _amount The amount of USDX to deposit and evenly distribute to ozUSD holders.
    function distributeYield(uint256 _amount) external nonReentrant onlyRole(YIELD_DISTRIBUTOR_ROLE) {
        if (_amount == 0) revert ZeroAmount();
        uint256 previousTotal = totalDeposited;
        IERC20Metadata(asset()).safeTransferFrom(msg.sender, address(this), _amount);
        totalDeposited += _amount;
        emit YieldDistributed(previousTotal, totalDeposited);
    }

    /// @notice This function allows the owner to pause or unpause this contract.
    /// @param  _set The boolean for whether the contract is to be paused or unpaused. True for paused, false otherwise.
    function setPaused(bool _set) external onlyOwner {
        _set ? _pause() : _unpause();
    }

    /// @notice Returns the maximum amount of assets that can be deposited for the `receiver`.
    /// @dev Overrides the ERC4626 implementation to return 0 when the contract is paused.
    /// @param _receiver The address of the receiver.
    /// @return Maximum amount of assets that can be deposited. Returns 0 when paused.
    function maxDeposit(address _receiver) public view override returns (uint256) {
        return paused() ? 0 : super.maxDeposit(_receiver);
    }

    /// @notice Returns the maximum amount of shares that can be minted for the `receiver`.
    /// @dev Overrides the ERC4626 implementation to return 0 when the contract is paused.
    /// @param _receiver The address of the receiver.
    /// @return Maximum amount of shares that can be minted. Returns 0 when paused.
    function maxMint(address _receiver) public view override returns (uint256) {
        return paused() ? 0 : super.maxMint(_receiver);
    }

    /// @notice Returns the maximum amount of assets that can be withdrawn by `owner`.
    /// @dev Overrides the ERC4626 implementation to return 0 when the contract is paused.
    /// @param _owner The address of the owner.
    /// @return Maximum amount of assets that can be withdrawn. Returns 0 when paused.
    function maxWithdraw(address _owner) public view override returns (uint256) {
        return paused() ? 0 : super.maxWithdraw(_owner);
    }

    /// @notice Returns the maximum amount of shares that can be redeemed by `owner`.
    /// @dev Overrides the ERC4626 implementation to return 0 when the contract is paused.
    /// @param _owner The address of the owner.
    /// @return Maximum amount of shares that can be redeemed. Returns 0 when paused.
    function maxRedeem(address _owner) public view override returns (uint256) {
        return paused() ? 0 : super.maxRedeem(_owner);
    }
}
