// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDEXAdapter {
    function getExpectedReturn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external returns (uint256);
    
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) external returns (uint256 amountOut);
    
    function isPairSupported(
        address tokenIn,
        address tokenOut
    ) external view returns (bool);
    
    function getName() external view returns (string memory);
}