// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./base_adapter_test.sol";
import "../src/adapters/impl/UniswapV2.sol";
import "../src/adapters/impl/SushiSwap.sol";
import "../src/adapters/impl/UniswapV3.sol";


contract UniswapV2AdapterTest is BaseDEXAdapterTest {
    // Адреса контрактов Uniswap V2
    address constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    
    function setUp() public override {
        super.setUp();
        
        UniswapV2Adapter uniswapAdapterImpl = new UniswapV2Adapter(UNISWAP_V2_ROUTER, UNISWAP_V2_FACTORY);
        adapter = IDEXAdapter(address(uniswapAdapterImpl));
        adapterName = "Uniswap V2";
    }
}

contract SushiSwapAdapterTest is BaseDEXAdapterTest {
    // Адреса контрактов SushiSwap
    address constant SUSHISWAP_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant SUSHISWAP_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    
    function setUp() public override {
        super.setUp();
        
        SushiSwapAdapter sushiswapAdapterImpl = new SushiSwapAdapter(SUSHISWAP_ROUTER, SUSHISWAP_FACTORY);
        adapter = IDEXAdapter(address(sushiswapAdapterImpl));
        adapterName = "SushiSwap";
    }
}

contract UniswapV3AdapterTest is BaseDEXAdapterTest {
    address constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant UNISWAP_V3_QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    
    function setUp() public override {
        super.setUp();
        
        UniswapV3Adapter uniswapV3AdapterImpl = new UniswapV3Adapter(
            UNISWAP_V3_ROUTER,
            UNISWAP_V3_FACTORY,
            UNISWAP_V3_QUOTER
        );
        adapter = IDEXAdapter(address(uniswapV3AdapterImpl));
        adapterName = "Uniswap V3";
    }
}
