// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/OuterChainRouter.sol";
import "../../src/OuterChainRegistry.sol";
import "../../src/InnerChainRouter.sol";

contract MockInnerChainRouter is IInnerRouter {
    event SwapCalled(string dexName, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, address recipient);
    
    uint256 private swapReturnAmount;
    
    constructor() {

    }
    
    function setSwapReturnAmount(uint256 amount) public {
        swapReturnAmount = amount;
    }
    
    function swap(
        string memory dexName,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) public override returns (uint256) {
        emit SwapCalled(dexName, tokenIn, tokenOut, amountIn, amountOutMin, recipient);
        return swapReturnAmount;
    }
}