// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/adapters/adapter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseDEXAdapterTest is Test {
    // Адреса токенов Ethereum Mainnet
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // Адрес кита с большим количеством токенов
    address constant WHALE = 0xf584F8728B874a6a5c7A8d4d387C9aae9172D621;

    address owner;
    address user;

    IERC20 wethToken;
    IERC20 usdcToken;
    IERC20 daiToken;
    IERC20 usdtToken;

    IDEXAdapter adapter;
    
    string adapterName;

    function setUp() public virtual {
        owner = address(this);
        user = address(0x123);
        
        vm.deal(user, 10 ether);

        wethToken = IERC20(WETH);
        usdcToken = IERC20(USDC);
        daiToken = IERC20(DAI);
        usdtToken = IERC20(USDT);

        dealTokens();
    }

    function dealTokens() internal {
        vm.startPrank(WHALE);

        uint256 daiAmount = 1000 * 10**18; // 1000 DAI
        uint256 usdcAmount = 1000 * 10**6;  // 1000 USDC

        require(daiToken.balanceOf(WHALE) >= daiAmount, "Whale doesn't have enough DAI");
        require(usdcToken.balanceOf(WHALE) >= usdcAmount, "Whale doesn't have enough USDC");

        daiToken.transfer(user, daiAmount);
        usdcToken.transfer(user, usdcAmount);

        vm.stopPrank();

        assertGe(daiToken.balanceOf(user), daiAmount);
        assertGe(usdcToken.balanceOf(user), usdcAmount);
    }

    function testAdapterInterface() public virtual {
        assertEq(adapter.getName(), adapterName);
    }


    function testIsPairSupported() public virtual {
        assertTrue(adapter.isPairSupported(DAI, USDC));
        assertTrue(adapter.isPairSupported(DAI, WETH));
        assertTrue(adapter.isPairSupported(USDC, WETH));

        address fakeToken = address(0x1111111111111111111111111111111111111111);
        assertFalse(adapter.isPairSupported(fakeToken, USDC));
    }


    function testGetExpectedReturn() public virtual {
        uint256 amountIn = 100 * 10**18; // 100 DAI
        
        // DAI -> USDC
        uint256 expectedUsdc = adapter.getExpectedReturn(DAI, USDC, amountIn);
        assertGt(expectedUsdc, 0, "Expected USDC return should be > 0");
        
        // DAI -> WETH
        uint256 expectedWeth = adapter.getExpectedReturn(DAI, WETH, amountIn);
        assertGt(expectedWeth, 0, "Expected WETH return should be > 0");
        
        // Логируем результаты
        console.log(adapterName, "DAI->USDC expected:", expectedUsdc / 10**6);
        console.log(adapterName, "DAI->WETH expected:", expectedWeth / 10**18);
    }

    function testSwap() public virtual {
        vm.startPrank(user);
        uint256 amountIn = 100 * 10**18; // 100 DAI
        
        uint256 expectedUsdc = adapter.getExpectedReturn(DAI, USDC, amountIn);
        uint256 minAmountOut = (expectedUsdc * 95) / 100; // 5% slippage
        
        daiToken.approve(address(adapter), amountIn);
        uint256 usdcBefore = usdcToken.balanceOf(user);
        uint256 receivedUsdc = adapter.swap(
            DAI,
            USDC,
            amountIn,
            minAmountOut,
            user
        );
        
        uint256 usdcAfter = usdcToken.balanceOf(user);
        assertEq(usdcAfter - usdcBefore, receivedUsdc, "Incorrect USDC amount received");
        assertGe(receivedUsdc, minAmountOut, "Received less than minimum expected");
        console.log(adapterName, "Swap 100 DAI -> USDC:", receivedUsdc / 10**6, "USDC");
        
        vm.stopPrank();
    }

    function testSwapWithDifferentAmounts() public virtual {
        vm.startPrank(user);
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 * 10**18;  // 10 DAI
        amounts[1] = 50 * 10**18;  // 50 DAI
        amounts[2] = 100 * 10**18; // 100 DAI
        
        for (uint i = 0; i < amounts.length; i++) {
            uint256 amountIn = amounts[i];
            
            uint256 expectedUsdc = adapter.getExpectedReturn(DAI, USDC, amountIn);
            uint256 minAmountOut = (expectedUsdc * 95) / 100; // 5% slippage
            daiToken.approve(address(adapter), amountIn);
            uint256 usdcBefore = usdcToken.balanceOf(user);
            uint256 receivedUsdc = adapter.swap(
                DAI,
                USDC,
                amountIn,
                minAmountOut,
                user
            );
            
            uint256 usdcAfter = usdcToken.balanceOf(user);
            assertEq(usdcAfter - usdcBefore, receivedUsdc, "Incorrect USDC amount received");
            assertGe(receivedUsdc, minAmountOut, "Received less than minimum expected");
            
            //console.log(adapterName, "Swap", amountIn / 10**18, "DAI -> USDC:", receivedUsdc / 10**6, "USDC");
        }
        
        vm.stopPrank();
    }

    function testSwapToWETH() public virtual {
        vm.startPrank(user);
        uint256 amountIn = 100 * 10**18; // 100 DAI
        uint256 expectedWeth = adapter.getExpectedReturn(DAI, WETH, amountIn);
        uint256 minAmountOut = (expectedWeth * 95) / 100; // 5% slippage
        daiToken.approve(address(adapter), amountIn);
        uint256 wethBefore = wethToken.balanceOf(user);
        uint256 receivedWeth = adapter.swap(
            DAI,
            WETH,
            amountIn,
            minAmountOut,
            user
        );
        
        uint256 wethAfter = wethToken.balanceOf(user);
        assertEq(wethAfter - wethBefore, receivedWeth, "Incorrect WETH amount received");
        assertGe(receivedWeth, minAmountOut, "Received less than minimum expected");
        
        console.log(adapterName, "Swap 100 DAI -> WETH:", receivedWeth / 10**18, "WETH");
        
        vm.stopPrank();
    }

    function testUnsupportedPair() public virtual {
        address fakeToken = address(0x1111111111111111111111111111111111111111);
        uint256 rate = adapter.getExpectedReturn(fakeToken, USDC, 1 ether);
        assertEq(rate, 0, "Should return 0 for unsupported pair");
    }
}
