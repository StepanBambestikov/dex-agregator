// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDEXAdapter} from "src/adapters/adapter.sol";

contract MockDEXAdapter is IDEXAdapter {
    string private _name;
    bool private _isPairSupported;
    uint256 private _expectedReturn;
    
    constructor(string memory name) {
        _name = name;
        _isPairSupported = true;
        _expectedReturn = 1 ether;
    }
    
    function getName() external view override returns (string memory) {
        return _name;
    }
    
    function isPairSupported(address tokenIn, address tokenOut) external view override returns (bool) {
        return _isPairSupported;
    }
    
    function getExpectedReturn(address tokenIn, address tokenOut, uint256 amountIn) external override returns (uint256) {
        return _expectedReturn;
    }
    
    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, address recipient) external override returns (uint256) {
        return _expectedReturn;
    }
    
    // Функции для тестирования
    function setIsPairSupported(bool supported) external {
        _isPairSupported = supported;
    }
    
    function setExpectedReturn(uint256 expectedReturn) external {
        _expectedReturn = expectedReturn;
    }
}