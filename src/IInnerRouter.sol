// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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