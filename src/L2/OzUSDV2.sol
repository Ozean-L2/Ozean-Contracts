// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC4626, ERC20, IERC20Metadata, SafeERC20} from "openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ReentrancyGuard} from "openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";

/// @title  Ozean USD (ozUSD) Token Contract
/// @notice This contract represents a yield-bearing vault for USDX tokens, adhering to the ERC-4626 standard.
/// @dev    !!! NEEDS AN AUDIT !!!
///         Overrides _deposit() and _withdraw() flow to allow only the owner to distribute yield.
///         https://docs.euler.finance/creator-tools/security/attack-vectors/donation-attacks/
contract OzUSDV2 is ERC4626, ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20Metadata;

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
        require(_sharesAmount >= 1e18, "OzUSD: Must deploy with at least one USDX.");
        mint(_sharesAmount, address(0xdead));
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
    /// @notice Returns the total amount of USDX deposited in the vault (excluding yield).
    /// @return The total amount of assets deposited by users.
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
        super._withdraw(_caller, _receiver, _owner, _assets, _shares);
        totalDeposited -= _assets;
    }

    /// OWNER ///

    /// @notice Distributes the yield to the protocol by updating the total pooled USDX balance.
    /// @param _amount The amount of USDX to deposit and evenly distribute to ozUSD holders.
    function distributeYield(uint256 _amount) external nonReentrant onlyOwner {
        IERC20Metadata(asset()).safeTransferFrom(msg.sender, address(this), _amount);
        totalDeposited += _amount;
        emit YieldDistributed(totalAssets() - _amount, totalAssets());
    }

    /// @notice This function allows the owner to pause or unpause this contract.
    /// @param  _set The boolean for whether the contract is to be paused or unpaused. True for paused, false otherwise.
    function setPaused(bool _set) external onlyOwner {
        _set ? _pause() : _unpause();
    }
}
