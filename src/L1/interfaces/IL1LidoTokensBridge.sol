// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IL1LidoTokensBridge {
    function depositERC20To(
        address l1Token_,
        address l2Token_,
        address to_,
        uint256 amount_,
        uint32 l2Gas_,
        bytes calldata data_
    ) external;
}
