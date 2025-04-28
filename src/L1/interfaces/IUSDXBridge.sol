// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IUSDXBridge {
    function bridge(address _stablecoin, uint256 _amount, address _to) external;
}
