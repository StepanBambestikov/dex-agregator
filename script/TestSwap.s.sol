// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/OuterChainRouter.sol";

contract TestSwap is Script {
    //Sepolia
    address constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address constant USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant OUTER_ROUTER = 0xd993A31234C12139022b2351495EFD1E124be0cD; 
    
    function run() external {
        vm.startBroadcast();
        
        OuterChainRouter.SwapCommand memory swapCommand = OuterChainRouter.SwapCommand({
            dexName: "UniswapV2", 
            tokenIn: WETH,
            tokenOut: USDC,
            amountIn: 0.0001 ether, // 0.001 WETH
            amountOutMin: 0, 
            recipient: msg.sender
        });
        
        bytes memory encodedCommand = abi.encode(swapCommand);
        
        bytes[] memory commands = new bytes[](1);
        commands[0] = abi.encodePacked(uint8(1), encodedCommand); // 1 = SWAP_COMMAND
        
        (bool successBalance,) = WETH.staticcall(
            abi.encodeWithSignature("balanceOf(address)", msg.sender)
        );
        if (successBalance) {
            console.log("WETH balance check successful");
        } else {
            console.log("Failed to check WETH balance");
        }
        console.log("Approving WETH for router...");
        (bool success, ) = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14.call{gas: 100000}(
            abi.encodeWithSignature("approve(address,uint256)", OUTER_ROUTER, 1e14)
        );
        console.log("Approved successfully. Allowance:", IERC20(WETH).allowance(msg.sender, OUTER_ROUTER));
        require(success, "Approve failed");
        
        console.log("Executing swap command...");
        OuterChainRouter(payable(OUTER_ROUTER)).executeCommands(commands);
        
        console.log("Swap command executed");
        vm.stopBroadcast();
    }
}