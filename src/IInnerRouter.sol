// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//The interface is used by the OuterChainRouter to effectively replace it with a mock during unit testing.
interface IInnerRouter {
    function swap(
        string memory dexName,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) external returns (uint256);
}