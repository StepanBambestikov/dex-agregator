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

contract DeployWithConfig is Script {

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

    function configureRegistryForCrossChain(
        OuterChainRegistry registry,
        string memory chainName,
        string memory destinationChain,
        address routerAddress
    ) internal {
        string memory routerAddressString = toAsciiString(routerAddress);
        
        registry.setChainName(1, chainName);
        registry.setRemoteRouterAddress(destinationChain, "0x0000000000000000000000000000000000000000"); 
    }
    
    function deployToEthereum() public {
        DeploymentConfig memory config = DeploymentConfig({
            chainName: "ethereum",
            destinationChain: "optimism",
            axelarGateway: 0x4F4495243837681061C4743b74B3eEdf548D56A5,
            axelarGasService: 0x2d5d7d31F671F86C782533cc367F14109a082712,
            uniswapV2Router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            uniswapV2Factory: 0xF62c03E08ada871A0bEb309762E260a7a6a880E6,
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
            
            (bool success, ) = address(uniswapV2Adapter).call(
                abi.encodeWithSignature("isPairSupported(address,address)", address(0), address(0))
            );
            require(success, "UniswapV2Adapter: Invalid interface");

            registry.addAdapter("UniswapV2", address(uniswapV2Adapter));
            console.log("Deployed UniswapV2Adapter at:", address(uniswapV2Adapter));
        }
        
        if (config.deploySushi) {
            require(config.sushiswapRouter != address(0) && config.sushiswapFactory != address(0), "SushiSwap addresses required");
            SushiSwapAdapter sushiswapAdapter = new SushiSwapAdapter(config.sushiswapRouter, config.sushiswapFactory);
            
            (bool success, ) = address(sushiswapAdapter).call(
                abi.encodeWithSignature("isPairSupported(address,address)", address(0), address(0))
            );
            require(success, "SushiSwapAdapter: Invalid interface");
            
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

            (bool success, ) = address(uniswapV3Adapter).call(
                abi.encodeWithSignature("isPairSupported(address,address)", address(0), address(0))
            );
            require(success, "UniswapV3Adapter: Invalid interface");

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

    function _printDeploymentSummary(
        DeploymentConfig memory config,
        address registry,
        address router,
        address outerRegistry,
        address outerRouter
    ) internal pure {
        console.log("\n=== Deployment Summary ===");
        console.log("Network: %s", config.chainName);
        console.log("Destination Chain: %s", config.destinationChain);
        console.log("--------------------------");
        console.log("Core Contracts:");
        console.log("- InnerChainRegistry: %s", registry);
        console.log("- InnerChainRouter: %s", router);
        console.log("- OuterChainRegistry: %s", outerRegistry);
        console.log("- OuterChainRouter: %s", outerRouter);
        console.log("--------------------------");
        console.log("DEX Adapters Configured:");
        if (config.deployUniV2) console.log("- UniswapV2: Enabled");
        if (config.deploySushi) console.log("- SushiSwap: Enabled");
        if (config.deployUniV3) console.log("- UniswapV3: Enabled");
        console.log("--------------------------");
        console.log("Axelar Configuration:");
        console.log("- Gateway: %s", config.axelarGateway);
        console.log("- Gas Service: %s", config.axelarGasService);
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
            uniswapV2Router: 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3,
            uniswapV2Factory: 0xF62c03E08ada871A0bEb309762E260a7a6a880E6,
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
    
    function char(bytes1 b) internal pure returns (bytes1) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}