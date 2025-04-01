// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/InnerChainRegistry.sol";
import "./mocks/MockDexAdapter.sol";

contract InnerChainRegistryTest is Test {
    InnerChainRegistry public registry;
    address public owner;
    MockDEXAdapter public uniswapAdapter;
    MockDEXAdapter public sushiswapAdapter;
    
    event AdapterAdded(string indexed dexName, address adapter);
    event AdapterUpdated(string indexed dexName, address oldAdapter, address newAdapter);
    event AdapterRemoved(string indexed dexName);
    event AdapterStatusChanged(string indexed dexName, bool isActive);

    function setUp() public {
        owner = address(this);
        registry = new InnerChainRegistry();
        
        uniswapAdapter = new MockDEXAdapter("Uniswap");
        sushiswapAdapter = new MockDEXAdapter("Sushiswap");
    }
    
    function testAddAdapter() public {
        vm.expectEmit(true, true, true, true);
        emit AdapterAdded("uniswap", address(uniswapAdapter));
        
        registry.addAdapter("uniswap", address(uniswapAdapter));
        
        (address adapterAddress, bool isActive) = registry.getAdapterInfo("uniswap");
        assertEq(adapterAddress, address(uniswapAdapter));
        assertTrue(isActive);
        
        string[] memory dexNames = registry.getAllDexNames();
        assertEq(dexNames.length, 1);
        assertEq(dexNames[0], "uniswap");
        
        bool isRegistered = registry.isDexRegistered("uniswap");
        assertTrue(isRegistered);
    }
  
    function testAddMultipleAdapters() public {
        registry.addAdapter("uniswap", address(uniswapAdapter));
        registry.addAdapter("sushiswap", address(sushiswapAdapter));
        
        string[] memory dexNames = registry.getAllDexNames();
        assertEq(dexNames.length, 2);
        bool foundUniswap = false;
        bool foundSushiswap = false;
        
        for (uint i = 0; i < dexNames.length; i++) {
            if (keccak256(bytes(dexNames[i])) == keccak256(bytes("uniswap"))) {
                foundUniswap = true;
            }
            if (keccak256(bytes(dexNames[i])) == keccak256(bytes("sushiswap"))) {
                foundSushiswap = true;
            }
        }
        
        assertTrue(foundUniswap);
        assertTrue(foundSushiswap);
    }
    
    function testAddDuplicateDex() public {
        registry.addAdapter("uniswap", address(uniswapAdapter));
        vm.expectRevert();
        registry.addAdapter("uniswap", address(sushiswapAdapter));
    }
    
    function testAddEmptyDexName() public {
        vm.expectRevert();
        registry.addAdapter("", address(uniswapAdapter));
    }
    
    function testAddZeroAddress() public {
        vm.expectRevert();
        registry.addAdapter("uniswap", address(0)); 
    }
    
    function testUpdateAdapter() public {
        registry.addAdapter("uniswap", address(uniswapAdapter));
        
        MockDEXAdapter newAdapter = new MockDEXAdapter("Uniswap V3");
        
        vm.expectEmit(true, true, true, true);
        emit AdapterUpdated("uniswap", address(uniswapAdapter), address(newAdapter));
        
        registry.updateAdapter("uniswap", address(newAdapter));
        
        (address adapterAddress, ) = registry.getAdapterInfo("uniswap");
        assertEq(adapterAddress, address(newAdapter));
    }
    
    function testUpdateNonExistentDex() public {
        vm.expectRevert();
        registry.updateAdapter("nonexistent", address(uniswapAdapter));
    }
    
    function testUpdateToSameAddress() public {
        registry.addAdapter("uniswap", address(uniswapAdapter));
        vm.expectRevert();
        registry.updateAdapter("uniswap", address(uniswapAdapter));
    }
    
    function testSetAdapterStatus() public {
        registry.addAdapter("uniswap", address(uniswapAdapter));
        
        vm.expectEmit(true, true, true, true);
        emit AdapterStatusChanged("uniswap", false);
        
        registry.setAdapterStatus("uniswap", false);
        
        (address adapterAddress, bool isActive) = registry.getAdapterInfo("uniswap");
        assertEq(adapterAddress, address(uniswapAdapter));
        assertFalse(isActive);
    }
    
    function testSetSameStatus() public {
        registry.addAdapter("uniswap", address(uniswapAdapter));
        vm.expectRevert();
        registry.setAdapterStatus("uniswap", true);
    }
    
    function testRemoveAdapter() public {
        registry.addAdapter("uniswap", address(uniswapAdapter));
        registry.addAdapter("sushiswap", address(sushiswapAdapter));
        
        vm.expectEmit(true, true, true, true);
        emit AdapterRemoved("uniswap");
        
        registry.removeAdapter("uniswap");
        
        string[] memory dexNames = registry.getAllDexNames();
        assertEq(dexNames.length, 1);
        assertEq(dexNames[0], "sushiswap");
        
        bool isRegistered = registry.isDexRegistered("uniswap");
        assertFalse(isRegistered);
    }
}