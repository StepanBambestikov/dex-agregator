// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/InnerChainRouter.sol";
import "../src/InnerChainRegistry.sol";
import "../src/adapters/adapter.sol";
import "../src/adapters/impl/UniswapV2.sol";
import "../src/adapters/impl/SushiSwap.sol";
import "../src/adapters/impl/UniswapV3.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InnerChainRouterTest is Test {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address constant WHALE = 0xf584F8728B874a6a5c7A8d4d387C9aae9172D621;

    address constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant SUSHISWAP_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant SUSHISWAP_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant UNISWAP_V3_QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    address owner;
    address user;

    IERC20 wethToken;
    IERC20 usdcToken;
    IERC20 daiToken;
    IERC20 usdtToken;

    InnerChainRegistry registry;
    InnerChainRouter router;
    
    UniswapV2Adapter uniswapV2Adapter;
    SushiSwapAdapter sushiswapAdapter;
    UniswapV3Adapter uniswapV3Adapter;

    function setUp() public {
        owner = address(this);
        user = address(0x123);
        
        vm.deal(user, 10 ether);

        wethToken = IERC20(WETH);
        usdcToken = IERC20(USDC);
        daiToken = IERC20(DAI);
        usdtToken = IERC20(USDT);

        registry = new InnerChainRegistry();
        
        uniswapV2Adapter = new UniswapV2Adapter(UNISWAP_V2_ROUTER, UNISWAP_V2_FACTORY);
        sushiswapAdapter = new SushiSwapAdapter(SUSHISWAP_ROUTER, SUSHISWAP_FACTORY);
        uniswapV3Adapter = new UniswapV3Adapter(UNISWAP_V3_ROUTER, UNISWAP_V3_FACTORY, UNISWAP_V3_QUOTER);
        
        registry.addAdapter("UniswapV2", address(uniswapV2Adapter));
        registry.addAdapter("SushiSwap", address(sushiswapAdapter));
        registry.addAdapter("UniswapV3", address(uniswapV3Adapter));
        
        router = new InnerChainRouter(registry);
        
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

    function testRouterInitialization() public {
        assertEq(address(router.registry()), address(registry));
        assertTrue(registry.isDexRegistered("UniswapV2"));
        assertTrue(registry.isDexRegistered("SushiSwap"));
        assertTrue(registry.isDexRegistered("UniswapV3"));
    }

    function testIsPairSupported() public {
        assertTrue(router.isPairSupported("UniswapV2", DAI, USDC));
        assertTrue(router.isPairSupported("SushiSwap", DAI, USDC));
        assertTrue(router.isPairSupported("UniswapV3", DAI, USDC));
        
        address fakeToken = address(0x1111111111111111111111111111111111111111);
        assertFalse(router.isPairSupported("UniswapV2", fakeToken, USDC));
    }

    function testGetExpectedReturn() public {
        uint256 amountIn = 100 * 10**18; // 100 DAI
        
        uint256 expectedUniswapV2 = router.getExpectedReturn("UniswapV2", DAI, USDC, amountIn);
        uint256 expectedSushiSwap = router.getExpectedReturn("SushiSwap", DAI, USDC, amountIn);
        uint256 expectedUniswapV3 = router.getExpectedReturn("UniswapV3", DAI, USDC, amountIn);
        
        assertGt(expectedUniswapV2, 0);
        assertGt(expectedSushiSwap, 0);
        assertGt(expectedUniswapV3, 0);
        
        console.log("UniswapV2 expected return for 100 DAI -> USDC:", expectedUniswapV2 / 10**6);
        console.log("SushiSwap expected return for 100 DAI -> USDC:", expectedSushiSwap / 10**6);
        console.log("UniswapV3 expected return for 100 DAI -> USDC:", expectedUniswapV3 / 10**6);
    }

    function testFindBestDex() public {
        uint256 amountIn = 100 * 10**18; // 100 DAI
        
        (string memory bestDex, uint256 bestReturn) = router.findBestDex(DAI, USDC, amountIn);
        
        assertGt(bestReturn, 0);
        assertFalse(bytes(bestDex).length == 0);
        
        console.log("Best DEX for 100 DAI -> USDC:", bestDex);
        console.log("Best return:", bestReturn / 10**6);
    }

    function testSwap() public {
        vm.startPrank(user);
        uint256 amountIn = 100 * 10**18; // 100 DAI
        
        uint256 expectedReturn = router.getExpectedReturn("UniswapV2", DAI, USDC, amountIn);
        uint256 minAmountOut = (expectedReturn * 95) / 100; // 5% slippage
        
        daiToken.approve(address(router), amountIn);
        
        uint256 usdcBefore = usdcToken.balanceOf(user);
        
        uint256 receivedUsdc = router.swap(
            "UniswapV2",
            DAI,
            USDC,
            amountIn,
            minAmountOut,
            user
        );
        
        console.log("Expected return:", expectedReturn / 10**6);
        console.log("Minimum amount out:", minAmountOut / 10**6);
        console.log("USDC before:", usdcBefore / 10**6);
        console.log("USDC receivedUsdc:", receivedUsdc / 10**6);
        console.log("USDC after:", usdcToken.balanceOf(user) / 10**6);
        console.log("USDC difference:", (usdcToken.balanceOf(user) - usdcBefore) / 10**6);

        uint256 usdcAfter = usdcToken.balanceOf(user);
        assertEq(usdcAfter - usdcBefore, receivedUsdc);
        assertGe(receivedUsdc, minAmountOut);
        
        console.log("Swapped 100 DAI -> USDC via router:", receivedUsdc / 10**6);
        vm.stopPrank();
    }

    function testSwapWithBestDex() public {
        vm.startPrank(user);
        uint256 amountIn = 100 * 10**18; // 100 DAI
        
        (string memory bestDex, uint256 bestReturn) = router.findBestDex(DAI, USDC, amountIn);
        uint256 minAmountOut = (bestReturn * 95) / 100; // 5% slippage
        
        daiToken.approve(address(router), amountIn);
        
        uint256 usdcBefore = usdcToken.balanceOf(user);
        
        uint256 receivedUsdc = router.swap(
            bestDex,
            DAI,
            USDC,
            amountIn,
            minAmountOut,
            user
        );
        
        uint256 usdcAfter = usdcToken.balanceOf(user);
        assertEq(usdcAfter - usdcBefore, receivedUsdc);
        assertGe(receivedUsdc, minAmountOut);
        
        console.log("Swapped 100 DAI -> USDC via best DEX (%s): %s", bestDex, receivedUsdc / 10**6);
        vm.stopPrank();
    }

    function testSwapWithDifferentAmounts() public {
        vm.startPrank(user);
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 * 10**18;  // 10 DAI
        amounts[1] = 50 * 10**18;  // 50 DAI
        amounts[2] = 100 * 10**18; // 100 DAI
        
        for (uint i = 0; i < amounts.length; i++) {
            uint256 amountIn = amounts[i];
            
            (string memory bestDex, uint256 bestReturn) = router.findBestDex(DAI, USDC, amountIn);
            uint256 minAmountOut = (bestReturn * 95) / 100; // 5% slippage
            
            daiToken.approve(address(router), amountIn);
            
            uint256 usdcBefore = usdcToken.balanceOf(user);
            
            uint256 receivedUsdc = router.swap(
                bestDex,
                DAI,
                USDC,
                amountIn,
                minAmountOut,
                user
            );
            
            uint256 usdcAfter = usdcToken.balanceOf(user);
            assertEq(usdcAfter - usdcBefore, receivedUsdc);
            assertGe(receivedUsdc, minAmountOut);
            
            console.log("Swapped %s DAI -> USDC via %s: %s", amountIn / 10**18, bestDex, receivedUsdc / 10**6);
        }
        
        vm.stopPrank();
    }

    function testSwapToWETH() public {
        vm.startPrank(user);
        uint256 amountIn = 100 * 10**18; // 100 DAI
        
        (string memory bestDex, uint256 bestReturn) = router.findBestDex(DAI, WETH, amountIn);
        uint256 minAmountOut = (bestReturn * 95) / 100; // 5% slippage
        
        daiToken.approve(address(router), amountIn);
        
        uint256 wethBefore = wethToken.balanceOf(user);
        
        uint256 receivedWeth = router.swap(
            bestDex,
            DAI,
            WETH,
            amountIn,
            minAmountOut,
            user
        );
        
        uint256 wethAfter = wethToken.balanceOf(user);
        assertEq(wethAfter - wethBefore, receivedWeth);
    }
}