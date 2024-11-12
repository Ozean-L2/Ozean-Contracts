// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor() ERC20("TEST", "TST", 18) { }

    function mint(address to, uint256 value) public {
        _mint(to, value);
    }
}

contract TestERC20Decimals is ERC20 {
    constructor(uint8 _decimals) ERC20("TEST", "TST", _decimals) { }

    function mint(address to, uint256 value) public {
        _mint(to, value);
    }
}

contract TestStETH is ERC20 {
    constructor() ERC20("staked ETH", "STETH", 18) { }

    function submit(address _referral) external payable returns (uint256) {
        _referral;
        _mint(msg.sender, msg.value);
        return msg.value;
    }
}

contract TestWstETH is ERC20 {
    address public immutable stETH;

    constructor(address _stETH) ERC20("Wrapped Staked ETH", "WSTETH", 18) {
        stETH = _stETH;
    }

    function wrap(uint256 _stETHAmount) external returns (uint256) {
        ERC20(stETH).transferFrom(msg.sender, address(this), _stETHAmount);
        uint256 wstETHAmount = getWstETHByStETH(_stETHAmount);
        _mint(msg.sender, wstETHAmount);
        return wstETHAmount;
    }

    /// @dev Hard code stETH/wstETH factor of 0.9
    function getWstETHByStETH(uint256 _stETHAmount) public pure returns (uint256) {
        return (_stETHAmount * 9) / 10;
    }
}
