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

    /// @dev See {IERC4626-deposit}.
    function deposit(uint256 assets, address receiver)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        shares = super.deposit(assets, receiver);
    }

    /// @dev See {IERC4626-mint}.
    function mint(uint256 shares, address receiver)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 assets)
    {
        assets = super.mint(shares, receiver);
    }

    /// @dev See {IERC4626-totalAssets}.
    function totalAssets() public view override returns (uint256) {
        return totalDeposited;
    }

    /// @dev See {IERC4626-_deposit}.
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);
        totalDeposited += assets;
    }

    /// @dev See {IERC4626-_withdraw}.
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        super._withdraw(caller, receiver, owner, assets, shares);
        totalDeposited -= assets;
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
