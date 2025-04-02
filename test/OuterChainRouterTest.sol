// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/OuterChainRouter.sol";
import "../src/OuterChainRegistry.sol";
import "../src/InnerChainRouter.sol";
import "./mocks/MockInnerChainRouter.sol";
import "./mocks/MockAlexaeGasService.sol";
import "./mocks/MockAlexarGateway.sol";
import "./mocks/MockERC20.sol";

contract OuterChainRouterAxelarTest is Test {
    OuterChainRouter public router;
    OuterChainRegistry public registry;
    MockInnerChainRouter public innerRouter;
    MockAxelarGateway public axelarGateway;
    MockAxelarGasService public axelarGasService;
    
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    MockERC20 public tokenC;
    
    address public owner;
    address public user;
    
    uint8 public constant SWAP_COMMAND = 1;
    uint8 public constant CROSS_CHAIN_COMMAND = 2;
    
    uint32 public constant ETHEREUM_CHAIN_ID = 1;
    uint32 public constant POLYGON_CHAIN_ID = 137;
    string public constant ETHEREUM_CHAIN_NAME = "Ethereum";
    string public constant POLYGON_CHAIN_NAME = "Polygon";
    string public constant REMOTE_ROUTER_ADDRESS = "0x1234567890123456789012345678901234567890";
    
    function setUp() public {
        owner = address(this);
        user = address(0x123);
        
        tokenA = new MockERC20("Token A", "TOKENA");
        tokenB = new MockERC20("Token B", "TOKENB");
        tokenC = new MockERC20("Token C", "TOKENC");
        
        tokenA.mint(user, 1000 ether);
        tokenB.mint(user, 1000 ether);
        tokenC.mint(user, 1000 ether);
        
        innerRouter = new MockInnerChainRouter();
        axelarGateway = new MockAxelarGateway();
        axelarGasService = new MockAxelarGasService();
        
        registry = new OuterChainRegistry();
        
        registry.setChainName(ETHEREUM_CHAIN_ID, ETHEREUM_CHAIN_NAME);
        registry.setChainName(POLYGON_CHAIN_ID, POLYGON_CHAIN_NAME);
        registry.setTokenSymbol(address(tokenA), "TOKENA");
        registry.setTokenSymbol(address(tokenB), "TOKENB");
        registry.setTokenSymbol(address(tokenC), "TOKENC");
        registry.setRemoteRouterAddress(POLYGON_CHAIN_NAME, REMOTE_ROUTER_ADDRESS);
        
        router = new OuterChainRouter(
            address(innerRouter),
            address(registry),
            address(axelarGateway),
            address(axelarGasService)
        );
        
        axelarGateway.setTokenAddress("TOKENA", address(tokenA));
        axelarGateway.setTokenAddress("TOKENB", address(tokenB));
        axelarGateway.setTokenAddress("TOKENC", address(tokenC));
        
        innerRouter.setSwapReturnAmount(0.9 ether);
        
        vm.startPrank(user);
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        tokenC.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }
    
    function createSwapCommand(
        string memory dexName,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) public pure returns (bytes memory) {
        OuterChainRouter.SwapCommand memory cmd = OuterChainRouter.SwapCommand(
            dexName,
            tokenIn,
            tokenOut,
            amountIn,
            amountOutMin,
            recipient
        );
        
        bytes memory encodedCmd = abi.encode(cmd);
        bytes memory result = new bytes(1 + encodedCmd.length);
        
        result[0] = bytes1(SWAP_COMMAND);
        
        for (uint256 i = 0; i < encodedCmd.length; i++) {
            result[i + 1] = encodedCmd[i];
        }
        
        return result;
    }
    
    function createCrossChainCommand(
        uint32 destinationChainId,
        address tokenToSend,
        uint256 amount,
        bytes memory destinationAddress,
        bytes memory extraData
    ) public pure returns (bytes memory) {
        OuterChainRouter.CrossChainCommand memory cmd = OuterChainRouter.CrossChainCommand(
            destinationChainId,
            tokenToSend,
            amount,
            destinationAddress,
            extraData
        );
        
        bytes memory encodedCmd = abi.encode(cmd);
        bytes memory result = new bytes(1 + encodedCmd.length);
        
        result[0] = bytes1(CROSS_CHAIN_COMMAND);
        
        for (uint256 i = 0; i < encodedCmd.length; i++) {
            result[i + 1] = encodedCmd[i];
        }
        
        return result;
    }

    function testExecuteCommandsWithSwap() public {
        bytes memory swapCmd = createSwapCommand(
            "Uniswap",
            address(tokenA),
            address(tokenB),
            1 ether,
            0.9 ether,
            user
        );
        
        bytes[] memory commands = new bytes[](1);
        commands[0] = swapCmd;
        
        assertEq(tokenA.balanceOf(user), 1000 ether);
        
        vm.prank(user);
        router.executeCommands(commands);
        
        assertEq(tokenA.balanceOf(user), 999 ether);
    }
    
    function testExecuteCommandsWithCrossChain() public {
        bytes memory receiverAddress = bytes("0x0000000000000000000000000000000000000abc");

        bytes memory crossChainCmd = createCrossChainCommand(
            POLYGON_CHAIN_ID,
            address(tokenC),
            2 ether,
            receiverAddress,
            bytes("")
        );
        
        bytes[] memory commands = new bytes[](1);
        commands[0] = crossChainCmd;
        
        assertEq(tokenC.balanceOf(user), 1000 ether);
        
        vm.prank(user);
        router.executeCommands{value: 0.01 ether}(commands);
        
        assertEq(tokenC.balanceOf(user), 998 ether);
    }
    
    function testExecuteCommandsWithSequence() public {
        bytes memory swapCmd = createSwapCommand(
            "Uniswap",
            address(tokenA),
            address(tokenB),
            1 ether,
            0.9 ether,
            user
        );
        
        bytes memory receiverAddress = bytes("0x0000000000000000000000000000000000000abc");
        
        bytes memory crossChainCmd = createCrossChainCommand(
            POLYGON_CHAIN_ID,
            address(tokenC),
            2 ether,
            receiverAddress,
            bytes("")
        );
        
        bytes memory swapCmd2 = createSwapCommand(
            "Sushiswap",
            address(tokenB),
            address(tokenA),
            0.5 ether,
            0.45 ether,
            user
        );
        
        bytes[] memory commands = new bytes[](3);
        commands[0] = swapCmd;
        commands[1] = crossChainCmd;
        commands[2] = swapCmd2;
        
        assertEq(tokenA.balanceOf(user), 1000 ether);
        assertEq(tokenC.balanceOf(user), 1000 ether);

        
        vm.prank(user);
        router.executeCommands{value: 0.01 ether}(commands);

        assertEq(tokenA.balanceOf(user), 999 ether);
        assertEq(tokenC.balanceOf(user), 998 ether);
        
        
    }
    
    function testExecuteWithToken() public {
        bytes memory swapCmd = createSwapCommand(
            "Uniswap",
            address(tokenA), 
            address(tokenB),
            3 ether, 
            2.7 ether, 
            user
        );
        
        bytes[] memory commands = new bytes[](1);
        commands[0] = swapCmd;
        
        bytes memory payload = abi.encode(bytes("destination_address"), commands);
        
        tokenA.mint(address(axelarGateway), 3 ether);
        
        vm.prank(address(axelarGateway));
        tokenA.approve(address(router), 3 ether);
        
        vm.prank(address(axelarGateway));
        router.executeWithToken(
            POLYGON_CHAIN_NAME,
            REMOTE_ROUTER_ADDRESS,
            payload,
            "TOKENA"
        );
        
    }
    
    function testExecuteWithTokenNotFromGateway() public {
        bytes memory payload = abi.encode(bytes("destination_address"), new bytes[](0));
        
        vm.expectRevert();
        router.executeWithToken(
            ETHEREUM_CHAIN_NAME,
            REMOTE_ROUTER_ADDRESS,
            payload,
            "TOKENA"
        );
    }
    
    function testExecuteWithTokenFromUnknownSource() public {
        bytes memory payload = abi.encode(bytes("destination_address"), new bytes[](0));

        vm.prank(address(axelarGateway));
        vm.expectRevert();
        router.executeWithToken(
            ETHEREUM_CHAIN_NAME,
            "0xunknownAddress",
            payload,
            "TOKENA"
        );
    }
}