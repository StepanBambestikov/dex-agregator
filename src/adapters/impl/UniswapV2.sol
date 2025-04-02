// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IDEXAdapter} from "../adapter.sol";

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract UniswapV2Adapter is IDEXAdapter, Ownable {
    using SafeERC20 for IERC20;
    address public immutable uniswapRouter;
    address public immutable uniswapFactory;
    
    uint256 public swapDeadline = 300; //5 minutes
    constructor(address _router, address _factory) Ownable(msg.sender) {
        uniswapRouter = _router;
        uniswapFactory = _factory;
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
        
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        
        try IUniswapV2Router(uniswapRouter).getAmountsOut(amountIn, path) returns (uint[] memory amounts) {
            return amounts[1];
        } catch {
            return 0;
        }
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

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256 deadline = block.timestamp + swapDeadline;
        
        bytes memory data = abi.encodeWithSelector(
          IUniswapV2Router.swapExactTokensForTokens.selector,
          amountIn,
          amountOutMin,
          path,
          recipient,
          deadline
        );
        (bool success, bytes memory returnData) = uniswapRouter.delegatecall(data);
        require(success, "Delegatecall failed");
        uint[] memory amounts = abi.decode(returnData, (uint[]));
        
        amountOut = amounts[1];        
        return amountOut;
    }
    
    function isPairSupported(
        address tokenIn,
        address tokenOut
    ) public view override returns (bool) {
        if (tokenIn == tokenOut) return false;
        address pair = IUniswapV2Factory(uniswapFactory).getPair(tokenIn, tokenOut);
        return pair != address(0);
    }
    
    function getName() external view override returns (string memory) {
        return "Uniswap V2";
    }
    
    receive() external payable {}
}

