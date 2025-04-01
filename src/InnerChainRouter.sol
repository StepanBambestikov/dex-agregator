// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IDEXAdapter} from "src/adapters/adapter.sol";
import {InnerChainRegistry} from "src/InnerChainRegistry.sol";

contract InnerChainRouter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    InnerChainRegistry public registry;

    event Swapped(
        string indexed dexName,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(InnerChainRegistry _registry) Ownable(msg.sender){
        registry = _registry;
    }

    function isPairSupported(string memory dexName, address tokenIn, address tokenOut) 
        external 
        view 
        returns (bool) 
    {
        return _getNeededDexContract(dexName).isPairSupported(tokenIn, tokenOut);
    }

    function _getNeededDexContract(string memory dexName) private view returns (IDEXAdapter){
        require(registry.isDexRegistered(dexName), "No such dex");
        (address dexAddress, bool isActive) = registry.getAdapterInfo(dexName);
        require(isActive, "Dex is not active");
        return IDEXAdapter(dexAddress);
    }

    function getExpectedReturn(
        string memory dexName, 
        address tokenIn, 
        address tokenOut, 
        uint256 amountIn
    ) 
        external  
        returns (uint256) 
    {
        return _getNeededDexContract(dexName).getExpectedReturn(tokenIn, tokenOut, amountIn);
    }

    function findBestDex(
        address tokenIn, 
        address tokenOut, 
        uint256 amountIn
    ) 
        public 
        returns (string memory bestDex, uint256 bestReturn) 
    {
        bestReturn = 0;
        
        string[] memory dexNames = registry.getActiveDexNames();
        for (uint i = 0; i < dexNames.length; i++) {
            string memory dexName = dexNames[i];
            
            IDEXAdapter adapter = _getNeededDexContract(dexName);
            if (!adapter.isPairSupported(tokenIn, tokenOut)) continue;
            
            uint256 expectedReturn = adapter.getExpectedReturn(tokenIn, tokenOut, amountIn);
            
            if (expectedReturn > bestReturn) {
                bestReturn = expectedReturn;
                bestDex = dexName;
            }
        }
        
        return (bestDex, bestReturn);
    }

    function swap(
        string memory dexName,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) 
        external 
        nonReentrant 
        returns (uint256) 
    {
        if (recipient == address(0)) {
            recipient = msg.sender;
        }
        
        IDEXAdapter adapter = _getNeededDexContract(dexName);
        require(adapter.isPairSupported(tokenIn, tokenOut), "Pair not supported");

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn); //TODO delegatecall failed
        IERC20(tokenIn).approve(address(adapter), amountIn);

        uint256 amountOut = adapter.swap(
          tokenIn,
          tokenOut,
          amountIn,
          amountOutMin,
          address(this)
        );

        emit Swapped(
            dexName,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut
        );
        IERC20(tokenOut).safeTransfer(recipient, amountOut);
        return amountOut;
    }

    //receive() external payable {}
}