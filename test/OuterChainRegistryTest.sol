// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/OuterChainRegistry.sol";

contract OuterChainRegistryTest is Test {
    OuterChainRegistry public storage_;
    
    address private owner = address(0x1);
    address private authorizedRouter = address(0x2);
    address private unauthorizedRouter = address(0x3);
    address private bridge = address(0x4);
    
    function setUp() public {
        vm.startPrank(owner);
        storage_ = new OuterChainRegistry();
        storage_.setAuthorizedRouter(authorizedRouter, true);
        vm.stopPrank();
    }
    
    function testOwnership() public {
        assertEq(storage_.owner(), owner);
    }
    
    function testSetChainName() public {
        uint32 chainId = 1;
        string memory chainName = "Ethereum";
        
        vm.startPrank(unauthorizedRouter);
        vm.expectRevert("Caller is not an authorized router");
        storage_.setChainName(chainId, chainName);
        vm.stopPrank();
        
        vm.startPrank(authorizedRouter);
        storage_.setChainName(chainId, chainName);
        vm.stopPrank();
        
        assertEq(storage_.getChainName(chainId), chainName);
    }
    
    function testBatchSetChainNames() public {
        uint32[] memory chainIds = new uint32[](3);
        chainIds[0] = 1;
        chainIds[1] = 137;
        chainIds[2] = 43114;
        
        string[] memory chainNames = new string[](3);
        chainNames[0] = "Ethereum";
        chainNames[1] = "Polygon";
        chainNames[2] = "Avalanche";
        
        vm.startPrank(authorizedRouter);
        storage_.batchSetChainNames(chainIds, chainNames);
        vm.stopPrank();
        
        assertEq(storage_.getChainName(chainIds[0]), chainNames[0]);
        assertEq(storage_.getChainName(chainIds[1]), chainNames[1]);
        assertEq(storage_.getChainName(chainIds[2]), chainNames[2]);
    }
    
    function testSetTokenSymbol() public {
        address tokenAddress = address(0x5);
        string memory symbol = "USDC";
        
        vm.startPrank(authorizedRouter);
        storage_.setTokenSymbol(tokenAddress, symbol);
        vm.stopPrank();
        
        assertEq(storage_.getTokenSymbol(tokenAddress), symbol);
        assertEq(storage_.getTokenAddress(symbol), tokenAddress);
    }
    
    function testBatchSetTokenSymbols() public {
        address[] memory tokenAddresses = new address[](3);
        tokenAddresses[0] = address(0x5);
        tokenAddresses[1] = address(0x6);
        tokenAddresses[2] = address(0x7);
        
        string[] memory symbols = new string[](3);
        symbols[0] = "USDC";
        symbols[1] = "USDT";
        symbols[2] = "DAI";
        
        vm.startPrank(authorizedRouter);
        storage_.batchSetTokenSymbols(tokenAddresses, symbols);
        vm.stopPrank();
        
        assertEq(storage_.getTokenSymbol(tokenAddresses[0]), symbols[0]);
        assertEq(storage_.getTokenSymbol(tokenAddresses[1]), symbols[1]);
        assertEq(storage_.getTokenSymbol(tokenAddresses[2]), symbols[2]);
        
        assertEq(storage_.getTokenAddress(symbols[0]), tokenAddresses[0]);
        assertEq(storage_.getTokenAddress(symbols[1]), tokenAddresses[1]);
        assertEq(storage_.getTokenAddress(symbols[2]), tokenAddresses[2]);
    }
    
    function testSetRemoteRouterAddress() public {
        string memory chainName = "Ethereum";
        string memory routerAddress = "0x1234567890123456789012345678901234567890";
        
        vm.startPrank(authorizedRouter);
        storage_.setRemoteRouterAddress(chainName, routerAddress);
        vm.stopPrank();
        
        assertEq(storage_.getRemoteRouterAddress(chainName), routerAddress);
    }
    
    function testBatchSetRemoteRouterAddresses() public {
        string[] memory chainNames = new string[](3);
        chainNames[0] = "Ethereum";
        chainNames[1] = "Polygon";
        chainNames[2] = "Avalanche";
        
        string[] memory routerAddresses = new string[](3);
        routerAddresses[0] = "0x1111111111111111111111111111111111111111";
        routerAddresses[1] = "0x2222222222222222222222222222222222222222";
        routerAddresses[2] = "0x3333333333333333333333333333333333333333";
        
        vm.startPrank(authorizedRouter);
        storage_.batchSetRemoteRouterAddresses(chainNames, routerAddresses);
        vm.stopPrank();
        
        assertEq(storage_.getRemoteRouterAddress(chainNames[0]), routerAddresses[0]);
        assertEq(storage_.getRemoteRouterAddress(chainNames[1]), routerAddresses[1]);
        assertEq(storage_.getRemoteRouterAddress(chainNames[2]), routerAddresses[2]);
    }
    
    function testSetAuthorizedBridge() public {
        vm.startPrank(authorizedRouter);
        storage_.setAuthorizedBridge(bridge, true);
        vm.stopPrank();
        
        assertTrue(storage_.isBridgeAuthorized(bridge));
        
        vm.startPrank(authorizedRouter);
        storage_.setAuthorizedBridge(bridge, false);
        vm.stopPrank();
        
        assertFalse(storage_.isBridgeAuthorized(bridge));
    }
    
    function testBatchSetAuthorizedBridges() public {
        address[] memory bridges = new address[](3);
        bridges[0] = address(0x8);
        bridges[1] = address(0x9);
        bridges[2] = address(0x10);
        
        bool[] memory authorizations = new bool[](3);
        authorizations[0] = true;
        authorizations[1] = false;
        authorizations[2] = true;
        
        vm.startPrank(authorizedRouter);
        storage_.batchSetAuthorizedBridges(bridges, authorizations);
        vm.stopPrank();
        
        assertTrue(storage_.isBridgeAuthorized(bridges[0]));
        assertFalse(storage_.isBridgeAuthorized(bridges[1]));
        assertTrue(storage_.isBridgeAuthorized(bridges[2]));
    }
    
    function testInputValidation() public {
        vm.startPrank(authorizedRouter);
        
        vm.expectRevert("Chain name cannot be empty");
        storage_.setChainName(1, "");
        
        vm.expectRevert("Token address cannot be zero");
        storage_.setTokenSymbol(address(0), "TEST");
        
        vm.expectRevert("Symbol cannot be empty");
        storage_.setTokenSymbol(address(0x1), "");
        
        vm.expectRevert("Chain name cannot be empty");
        storage_.setRemoteRouterAddress("", "0x1234");
        
        vm.expectRevert("Router address cannot be empty");
        storage_.setRemoteRouterAddress("Ethereum", "");
        
        vm.expectRevert("Bridge address cannot be zero");
        storage_.setAuthorizedBridge(address(0), true);
        
        vm.stopPrank();
    }
    
    function testArrayMismatchValidation() public {
        vm.startPrank(authorizedRouter);
        
        uint32[] memory chainIds = new uint32[](2);
        chainIds[0] = 1;
        chainIds[1] = 2;
        
        string[] memory chainNames = new string[](1);
        chainNames[0] = "Ethereum";
        
        vm.expectRevert("Arrays length mismatch");
        storage_.batchSetChainNames(chainIds, chainNames);
        
        address[] memory tokenAddresses = new address[](2);
        tokenAddresses[0] = address(0x1);
        tokenAddresses[1] = address(0x2);
        
        string[] memory symbols = new string[](1);
        symbols[0] = "TEST";
        
        vm.expectRevert("Arrays length mismatch");
        storage_.batchSetTokenSymbols(tokenAddresses, symbols);
        
        string[] memory names = new string[](2);
        names[0] = "Ethereum";
        names[1] = "Polygon";
        
        string[] memory addresses = new string[](1);
        addresses[0] = "0x1234";
        
        vm.expectRevert("Arrays length mismatch");
        storage_.batchSetRemoteRouterAddresses(names, addresses);
        
        address[] memory bridges = new address[](2);
        bridges[0] = address(0x1);
        bridges[1] = address(0x2);
        
        bool[] memory authorizations = new bool[](1);
        authorizations[0] = true;
        
        vm.expectRevert("Arrays length mismatch");
        storage_.batchSetAuthorizedBridges(bridges, authorizations);
        
        vm.stopPrank();
    }
}