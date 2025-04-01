// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IDEXAdapter} from "../adapter.sol";

interface IUniswapV3Router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

interface IUniswapV3Quoter {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
}

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

// For Uniswap V3 Pool interface
interface IUniswapV3Pool {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
    
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
}

contract UniswapV3Adapter is IDEXAdapter, Ownable {
    using SafeERC20 for IERC20;
    address public immutable uniswapRouter;
    address public immutable uniswapFactory;
    address public immutable uniswapQuoter;
    
    uint24[3] public feeTiers = [500, 3000, 10000]; // 0.05%, 0.3%, 1%
    uint256 public swapDeadline = 300;
    
    constructor(address _router, address _factory, address _quoter) Ownable(msg.sender) {
        uniswapRouter = _router;
        uniswapFactory = _factory;
        uniswapQuoter = _quoter;
    }
    
    function setSwapDeadline(uint256 _newDeadline) external onlyOwner {
        swapDeadline = _newDeadline;
    }
    
    function getExpectedReturn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external override returns (uint256) {
        if (!isPairSupported(tokenIn, tokenOut)) {
            return 0;
        }
        
        uint256 bestAmountOut = 0;
        
        for (uint i = 0; i < feeTiers.length; i++) {
            uint24 fee = feeTiers[i];
            
            address pool = IUniswapV3Factory(uniswapFactory).getPool(tokenIn, tokenOut, fee);
            if (pool == address(0)) continue;
            
            try IUniswapV3Quoter(uniswapQuoter).quoteExactInputSingle(
                tokenIn,
                tokenOut,
                fee,
                amountIn,
                0
            ) returns (uint256 amountOut) {
                if (amountOut > bestAmountOut) {
                    bestAmountOut = amountOut;
                }
            } catch {
                continue;
            }
        }
        
        return bestAmountOut;
    }
    
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) external override returns (uint256 amountOut) {
        require(recipient != address(0), "Invalid recipient");
        require(amountIn > 0, "Amount in must be greater than 0");
        require(isPairSupported(tokenIn, tokenOut), "Pair not supported");
        
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn); //TODO delegatecall failed
        IERC20(tokenIn).approve(uniswapRouter, amountIn);
        
        (uint24 bestFee, bool foundPool) = findBestFee(tokenIn, tokenOut, amountIn);
        require(foundPool, "No liquidity pool found");
        
        IUniswapV3Router.ExactInputSingleParams memory params = IUniswapV3Router.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: bestFee,
            recipient: recipient,
            deadline: block.timestamp + swapDeadline,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0 
        });
        
        amountOut = IUniswapV3Router(uniswapRouter).exactInputSingle(params);
        
        return amountOut;
    }
    
    function isPairSupported(
        address tokenIn,
        address tokenOut
    ) public view override returns (bool) {
        if (tokenIn == tokenOut) return false;
        
        for (uint i = 0; i < feeTiers.length; i++) {
            address pool = IUniswapV3Factory(uniswapFactory).getPool(tokenIn, tokenOut, feeTiers[i]);
            if (pool != address(0)) {
                return true;
            }
        }
        
        return false;
    }
    
    function getName() external view override returns (string memory) {
        return "Uniswap V3";
    }
    
    function findBestFee(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint24 bestFee, bool foundPool) {
        uint256 bestAmountOut = 0;
        foundPool = false;
        
        for (uint i = 0; i < feeTiers.length; i++) {
            uint24 fee = feeTiers[i];
            
            address pool = IUniswapV3Factory(uniswapFactory).getPool(tokenIn, tokenOut, fee);
            if (pool == address(0)) continue;
            
            foundPool = true;
            
            try IUniswapV3Quoter(uniswapQuoter).quoteExactInputSingle(
                tokenIn,
                tokenOut,
                fee,
                amountIn,
                0
            ) returns (uint256 amountOut) {
                if (amountOut > bestAmountOut) {
                    bestAmountOut = amountOut;
                    bestFee = fee;
                }
            } catch {
                continue;
            }
        }
        
        return (bestFee, foundPool);
    }
    
    receive() external payable {}
}