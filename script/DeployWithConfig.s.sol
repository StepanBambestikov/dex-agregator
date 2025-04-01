// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/InnerChainRouter.sol";
import "../src/InnerChainRegistry.sol";
import "../src/adapters/impl/UniswapV2.sol";
import "../src/adapters/impl/SushiSwap.sol";
import "../src/adapters/impl/UniswapV3.sol";
import "../src/OuterChainRouter.sol";
import "../src/OuterChainRegistry.sol";

/**
 * Configurable deployment script that allows you to specify which DEX adapters to deploy
 * You can run this script with specific parameters to customize your deployment
 *
 * Example: 
 * forge script script/DeployWithConfig.s.sol:DeployWithConfig --rpc-url $YOUR_RPC_URL 
 *      --sig "deployWithConfig(string,string,address,address,address,address,address,address,address,bool,bool,bool)" 
 *      "ethereum" "optimism" 0x12345... 0x23456... 0x34567... 0x45678... 0x56789... 0x67890... 0x78901... true true true
 */
contract DeployWithConfig is Script {
    // Развертывание с настраиваемыми параметрами

    struct DeploymentConfig {
        string chainName;
        string destinationChain;
        address axelarGateway;
        address axelarGasService;
        address uniswapV2Router;
        address uniswapV2Factory;
        address sushiswapRouter;
        address sushiswapFactory;
        address uniswapV3Router;
        address uniswapV3Factory;
        address uniswapV3Quoter;
        bool deployUniV2;
        bool deploySushi;
        bool deployUniV3;
    }

    // function deployWithConfig(
    //     string memory chainName,             // Название текущей цепи для Axelar
    //     string memory destinationChain,      // Название целевой цепи для Axelar
    //     address axelarGateway,              // Адрес Axelar Gateway в текущей цепи
    //     address axelarGasService,           // Адрес Axelar Gas Service в текущей цепи
    //     address uniswapV2Router,            // Адрес UniswapV2 Router (0x0, если не используется)
    //     address uniswapV2Factory,           // Адрес UniswapV2 Factory (0x0, если не используется)
    //     address sushiswapRouter,            // Адрес SushiSwap Router (0x0, если не используется)
    //     address sushiswapFactory,           // Адрес SushiSwap Factory (0x0, если не используется)
    //     address uniswapV3Router,            // Адрес UniswapV3 Router (0x0, если не используется)
    //     address uniswapV3Factory,           // Адрес UniswapV3 Factory (0x0, если не используется)
    //     address uniswapV3Quoter,            // Адрес UniswapV3 Quoter (0x0, если не используется)
    //     bool deployUniV2,                   // Флаг для развертывания UniswapV2 адаптера
    //     bool deploySushi,                   // Флаг для развертывания SushiSwap адаптера
    //     bool deployUniV3                    // Флаг для развертывания UniswapV3 адаптера
    // ) public {
    //     console.log("\n=== Deploying to %s ===", chainName);
        
    //     vm.startBroadcast();
        
    //     // Deploy InnerChainRegistry
    //     InnerChainRegistry registry = new InnerChainRegistry();
    //     console.log("Deployed InnerChainRegistry at:", address(registry));
        
    //     // Deploy DEX adapters based on parameters
    //     if (deployUniV2) {
    //         require(uniswapV2Router != address(0) && uniswapV2Factory != address(0), "UniswapV2 addresses required");
    //         UniswapV2Adapter uniswapV2Adapter = new UniswapV2Adapter(uniswapV2Router, uniswapV2Factory);
    //         registry.addAdapter("UniswapV2", address(uniswapV2Adapter));
    //         console.log("Deployed UniswapV2Adapter at:", address(uniswapV2Adapter));
    //     }
        
    //     if (deploySushi) {
    //         require(sushiswapRouter != address(0) && sushiswapFactory != address(0), "SushiSwap addresses required");
    //         SushiSwapAdapter sushiswapAdapter = new SushiSwapAdapter(sushiswapRouter, sushiswapFactory);
    //         registry.addAdapter("SushiSwap", address(sushiswapAdapter));
    //         console.log("Deployed SushiSwapAdapter at:", address(sushiswapAdapter));
    //     }
        
    //     if (deployUniV3) {
    //         require(
    //             uniswapV3Router != address(0) && 
    //             uniswapV3Factory != address(0) && 
    //             uniswapV3Quoter != address(0), 
    //             "UniswapV3 addresses required"
    //         );
    //         UniswapV3Adapter uniswapV3Adapter = new UniswapV3Adapter(uniswapV3Router, uniswapV3Factory, uniswapV3Quoter);
    //         registry.addAdapter("UniswapV3", address(uniswapV3Adapter));
    //         console.log("Deployed UniswapV3Adapter at:", address(uniswapV3Adapter));
    //     }
        
    //     // Deploy InnerChainRouter
    //     InnerChainRouter router = new InnerChainRouter(registry);
    //     console.log("Deployed InnerChainRouter at:", address(router));
        
    //     // Deploy OuterChainRegistry
    //     OuterChainRegistry outerRegistry = new OuterChainRegistry();
    //     console.log("Deployed OuterChainRegistry at:", address(outerRegistry));
        
    //     // Deploy OuterChainRouterAxelar
    //     OuterChainRouter outerRouter = new OuterChainRouter(
    //         address(router),
    //         address(outerRegistry),
    //         axelarGateway,
    //         axelarGasService
    //     );
    //     console.log("Deployed OuterChainRouterAxelar at:", address(outerRouter));
        
    //     // Authorize the router to update the registry
    //     outerRegistry.setAuthorizedRouter(address(outerRouter), true);
        
    //     // Настройка cross-chain параметров
    //     configureRegistryForCrossChain(
    //         outerRegistry, 
    //         chainName, 
    //         destinationChain, 
    //         address(outerRouter)
    //     );
        
    //     vm.stopBroadcast();
        
    //     console.log("\n=== Deployment Summary ===");
    //     console.log("Chain Name:", chainName);
    //     console.log("InnerChainRegistry:", address(registry));
    //     console.log("InnerChainRouter:", address(router));
    //     console.log("OuterChainRegistry:", address(outerRegistry));
    //     console.log("OuterChainRouterAxelar:", address(outerRouter));
    //     console.log("Configured for cross-chain with:", destinationChain);
    // }
    
    // Настройка registry для кросс-чейн взаимодействия
    function configureRegistryForCrossChain(
        OuterChainRegistry registry,
        string memory chainName,
        string memory destinationChain,
        address routerAddress
    ) internal {
        // Здесь нужно будет заполнить реальными данными после деплоя
        // Для тестирования оставляем в таком виде
        string memory routerAddressString = toAsciiString(routerAddress);
        
        registry.setChainName(1, chainName); // Используем 1 как chainId для текущей цепи (замените на реальный)
        registry.setRemoteRouterAddress(destinationChain, "0x0000000000000000000000000000000000000000"); 
        // В будущем вы можете обновить адрес удаленного роутера после его деплоя
    }
    
    // Деплой в конкретные цепи
    function deployToEthereum() public {
        DeploymentConfig memory config = DeploymentConfig({
            chainName: "ethereum",
            destinationChain: "optimism",
            axelarGateway: 0x4F4495243837681061C4743b74B3eEdf548D56A5,
            axelarGasService: 0x2d5d7d31F671F86C782533cc367F14109a082712,
            uniswapV2Router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            uniswapV2Factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
            sushiswapRouter: 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F,
            sushiswapFactory: 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac,
            uniswapV3Router: 0xE592427A0AEce92De3Edee1F18E0157C05861564,
            uniswapV3Factory: 0x1F98431c8aD98523631AE4a59f267346ea31F984,
            uniswapV3Quoter: 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6,
            deployUniV2: true,
            deploySushi: true,
            deployUniV3: true
        });
        
        _deployWithConfig(config);
    }

    function _deployAdapters(InnerChainRegistry registry, DeploymentConfig memory config) internal {
        if (config.deployUniV2) {
            require(config.uniswapV2Router != address(0) && config.uniswapV2Factory != address(0), "UniswapV2 addresses required");
            UniswapV2Adapter uniswapV2Adapter = new UniswapV2Adapter(config.uniswapV2Router, config.uniswapV2Factory);
            registry.addAdapter("UniswapV2", address(uniswapV2Adapter));
            console.log("Deployed UniswapV2Adapter at:", address(uniswapV2Adapter));
        }
        
        if (config.deploySushi) {
            require(config.sushiswapRouter != address(0) && config.sushiswapFactory != address(0), "SushiSwap addresses required");
            SushiSwapAdapter sushiswapAdapter = new SushiSwapAdapter(config.sushiswapRouter, config.sushiswapFactory);
            registry.addAdapter("SushiSwap", address(sushiswapAdapter));
            console.log("Deployed SushiSwapAdapter at:", address(sushiswapAdapter));
        }
        
        if (config.deployUniV3) {
            require(
                config.uniswapV3Router != address(0) && 
                config.uniswapV3Factory != address(0) && 
                config.uniswapV3Quoter != address(0), 
                "UniswapV3 addresses required"
            );
            UniswapV3Adapter uniswapV3Adapter = new UniswapV3Adapter(
                config.uniswapV3Router, 
                config.uniswapV3Factory, 
                config.uniswapV3Quoter
            );
            registry.addAdapter("UniswapV3", address(uniswapV3Adapter));
            console.log("Deployed UniswapV3Adapter at:", address(uniswapV3Adapter));
        }
    }

    function _deployWithConfig(DeploymentConfig memory config) internal {
        console.log("\n=== Deploying to %s ===", config.chainName);
        
        vm.startBroadcast();
        
        // Deploy InnerChainRegistry
        InnerChainRegistry registry = new InnerChainRegistry();
        console.log("Deployed InnerChainRegistry at:", address(registry));
        
        // Deploy DEX adapters
        _deployAdapters(registry, config);
        
        // Deploy InnerChainRouter
        InnerChainRouter router = new InnerChainRouter(registry);
        console.log("Deployed InnerChainRouter at:", address(router));
        
        // Deploy OuterChainRegistry
        OuterChainRegistry outerRegistry = new OuterChainRegistry();
        console.log("Deployed OuterChainRegistry at:", address(outerRegistry));
        
        // Deploy OuterChainRouterAxelar
        OuterChainRouter outerRouter = new OuterChainRouter(
            address(router),
            address(outerRegistry),
            config.axelarGateway,
            config.axelarGasService
        );
        console.log("Deployed OuterChainRouterAxelar at:", address(outerRouter));
        
        // Authorize the router
        outerRegistry.setAuthorizedRouter(address(outerRouter), true);
        
        // Настройка cross-chain параметров
        configureRegistryForCrossChain(
            outerRegistry, 
            config.chainName, 
            config.destinationChain, 
            address(outerRouter)
        );
        
        vm.stopBroadcast();
        
        _printDeploymentSummary(config, address(registry), address(router), address(outerRegistry), address(outerRouter));
    }
    
    function deployToOptimism() public {
        DeploymentConfig memory config = DeploymentConfig({
            chainName: "optimism",
            destinationChain: "oethereumptimism",
            axelarGateway:  0x5769D84DD62a6fD969856c75c7D321b84d455929, // Axelar Gateway
            axelarGasService: 0x2d5d7d31F671F86C782533cc367F14109a082712, // Axelar Gas Service
            uniswapV2Router: address(0), // No UniV2 Router
            uniswapV2Factory: address(0), // No UniV2 Factory
            sushiswapRouter: address(0), // No Sushi Router
            sushiswapFactory: address(0), // No Sushi Factory
            uniswapV3Router: 0xE592427A0AEce92De3Edee1F18E0157C05861564, // UniV3 Router
            uniswapV3Factory: 0x1F98431c8aD98523631AE4a59f267346ea31F984, // UniV3 Factory
            uniswapV3Quoter: 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6, // UniV3 Quoter
            deployUniV2: false,
            deploySushi: false,
            deployUniV3: true
        });
        
        _deployWithConfig(config);
    }
    
    function deployToArbitrum() public {
        DeploymentConfig memory config = DeploymentConfig({
            chainName: "arbitrum",
            destinationChain: "ethereum",
            axelarGateway: 0xe432150cce91c13a887f7D836923d5597adD8E31,
            axelarGasService: 0x2d5d7d31F671F86C782533cc367F14109a082712,
            uniswapV2Router: address(0),
            uniswapV2Factory: address(0),
            sushiswapRouter: 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506,
            sushiswapFactory: 0xc35DADB65012eC5796536bD9864eD8773aBc74C4,
            uniswapV3Router: 0xE592427A0AEce92De3Edee1F18E0157C05861564,
            uniswapV3Factory: 0x1F98431c8aD98523631AE4a59f267346ea31F984,
            uniswapV3Quoter: 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6,
            deployUniV2: false,
            deploySushi: true,
            deployUniV3: true
        });
        
        _deployWithConfig(config);
    }

    function deployToGoerli() public {
        DeploymentConfig memory config = DeploymentConfig({
            chainName: "ethereum-2",
            destinationChain: "arbitrum-goerli",
            axelarGateway: 0xe432150cce91c13a887f7D836923d5597adD8E31,
            axelarGasService: 0x2d5d7d31F671F86C782533cc367F14109a082712,
            uniswapV2Router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            uniswapV2Factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
            sushiswapRouter: address(0),
            sushiswapFactory: address(0),
            uniswapV3Router: address(0),
            uniswapV3Factory: address(0),
            uniswapV3Quoter: address(0),
            deployUniV2: true,
            deploySushi: false,
            deployUniV3: false
        });
        
        _deployWithConfig(config);
    }

    function deployToArbitrumGoerli() public {
        DeploymentConfig memory config = DeploymentConfig({
            chainName: "arbitrum-goerli",
            destinationChain: "ethereum-2",
            axelarGateway: 0xe432150cce91c13a887f7D836923d5597adD8E31,
            axelarGasService: 0x2d5d7d31F671F86C782533cc367F14109a082712,
            uniswapV2Router: address(0),
            uniswapV2Factory: address(0),
            sushiswapRouter: address(0),
            sushiswapFactory: address(0),
            uniswapV3Router: address(0),
            uniswapV3Factory: address(0),
            uniswapV3Quoter: address(0),
            deployUniV2: false,
            deploySushi: false,
            deployUniV3: false
        });
        
        _deployWithConfig(config);
    }
    
    // Хелпер функция для преобразования адреса в строку
    function toAsciiString(address addr) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(addr)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(abi.encodePacked("0x", s));
    }
    
    // Хелпер функция для преобразования байта в символ
    function char(bytes1 b) internal pure returns (bytes1) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}