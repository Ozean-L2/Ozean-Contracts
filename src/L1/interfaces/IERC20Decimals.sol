// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice An interface which extends the IERC20 to include a decimals view function.
/// @dev    Any allow-listed stablecoin added to the bridge must conform to this interface.
interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}
