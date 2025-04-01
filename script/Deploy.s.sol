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

contract DeployScript is Script {
    // Chain IDs
    uint32 constant ETHEREUM_MAINNET = 1;
    uint32 constant OPTIMISM = 10;
    uint32 constant ARBITRUM = 42161;
    
    // Chain names for Axelar
    string constant ETHEREUM_CHAIN_NAME = "ethereum";
    string constant OPTIMISM_CHAIN_NAME = "optimism";
    string constant ARBITRUM_CHAIN_NAME = "arbitrum";
    
    // Testnet Chain IDs
    uint32 constant GOERLI = 5;
    uint32 constant SEPOLIA = 11155111;
    uint32 constant ARBITRUM_GOERLI = 421613;
    
    // Testnet Chain names for Axelar
    string constant GOERLI_CHAIN_NAME = "ethereum-2";
    string constant SEPOLIA_CHAIN_NAME = "sepolia";
    string constant ARBITRUM_GOERLI_CHAIN_NAME = "arbitrum-goerli";
    
    // DEX Addresses for Ethereum
    address constant ETHEREUM_UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant ETHEREUM_UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant ETHEREUM_SUSHISWAP_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant ETHEREUM_SUSHISWAP_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address constant ETHEREUM_UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant ETHEREUM_UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant ETHEREUM_UNISWAP_V3_QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    
    // DEX Addresses for Optimism
    address constant OPTIMISM_UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant OPTIMISM_UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant OPTIMISM_UNISWAP_V3_QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address constant OPTIMISM_VELODROME_ROUTER = 0xa062aE8A9c5e11aaA026fc2670B0D65cCc8B2858;
    address constant OPTIMISM_VELODROME_FACTORY = 0x25CbdDb98b35ab1FF77413456B31EC81A6B6B746;
    
    // DEX Addresses for Arbitrum
    address constant ARBITRUM_UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant ARBITRUM_UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant ARBITRUM_UNISWAP_V3_QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address constant ARBITRUM_SUSHISWAP_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address constant ARBITRUM_SUSHISWAP_FACTORY = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    
    // Goerli Testnet Addresses
    address constant GOERLI_UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant GOERLI_UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    
    // Axelar Gateway Addresses
    address constant ETHEREUM_AXELAR_GATEWAY = 0x4F4495243837681061C4743b74B3eEdf548D56A5;
    address constant ETHEREUM_AXELAR_GAS_SERVICE = 0x2d5d7d31F671F86C782533cc367F14109a082712;
    
    address constant OPTIMISM_AXELAR_GATEWAY = 0x5769D84DD62a6fD969856c75c7D321b84d455929;
    address constant OPTIMISM_AXELAR_GAS_SERVICE = 0x2d5d7d31F671F86C782533cc367F14109a082712;
    
    address constant ARBITRUM_AXELAR_GATEWAY = 0xe432150cce91c13a887f7D836923d5597adD8E31;
    address constant ARBITRUM_AXELAR_GAS_SERVICE = 0x2d5d7d31F671F86C782533cc367F14109a082712;
    
    // Testnet Axelar Gateway Addresses
    address constant GOERLI_AXELAR_GATEWAY = 0xe432150cce91c13a887f7D836923d5597adD8E31;
    address constant GOERLI_AXELAR_GAS_SERVICE = 0x2d5d7d31F671F86C782533cc367F14109a082712;
    
    address constant SEPOLIA_AXELAR_GATEWAY = 0xe432150cce91c13a887f7D836923d5597adD8E31;
    address constant SEPOLIA_AXELAR_GAS_SERVICE = 0x2d5d7d31F671F86C782533cc367F14109a082712;
    
    address constant ARBITRUM_GOERLI_AXELAR_GATEWAY = 0xe432150cce91c13a887f7D836923d5597adD8E31;
    address constant ARBITRUM_GOERLI_AXELAR_GAS_SERVICE = 0x2d5d7d31F671F86C782533cc367F14109a082712;
    
    // Deployed contract addresses across chains
    struct DeployedContracts {
        address innerChainRegistry;
        address innerChainRouter;
        address outerChainRegistry;
        address outerChainRouterAxelar;
    }
    
    // Map chain ID to deployed addresses
    mapping(uint32 => DeployedContracts) public deployedAddresses;
    
    // Store router addresses as strings for Axelar
    mapping(uint32 => string) public routerAddressesString;
    
    // Common token addresses and symbols
    struct TokenInfo {
        address tokenAddress;
        string symbol;
    }
    
    // Token mappings per chain
    mapping(uint32 => TokenInfo[]) public chainTokens;
    
    function run() public {
        // Setup token information
        setupTokenInfo();
        
        // Deploy to Ethereum
        deployToEthereum();
        
        // Deploy to Optimism
        deployToOptimism();
        
        // Deploy to Arbitrum
        deployToArbitrum();
        
        // Configure cross-chain settings
        configureCrossChainSettings();
        
        // Log deployment summary
        logDeploymentSummary();
    }
    
    function setupTokenInfo() internal {
        // Ethereum tokens
        chainTokens[ETHEREUM_MAINNET].push(TokenInfo(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, "WETH"));
        chainTokens[ETHEREUM_MAINNET].push(TokenInfo(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, "USDC"));
        chainTokens[ETHEREUM_MAINNET].push(TokenInfo(0x6B175474E89094C44Da98b954EedeAC495271d0F, "DAI"));
        chainTokens[ETHEREUM_MAINNET].push(TokenInfo(0xdAC17F958D2ee523a2206206994597C13D831ec7, "USDT"));
        
        // Optimism tokens
        chainTokens[OPTIMISM].push(TokenInfo(0x4200000000000000000000000000000000000006, "WETH"));
        chainTokens[OPTIMISM].push(TokenInfo(0x7F5c764cBc14f9669B88837ca1490cCa17c31607, "USDC"));
        chainTokens[OPTIMISM].push(TokenInfo(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1, "DAI"));
        chainTokens[OPTIMISM].push(TokenInfo(0x94b008aA00579c1307B0EF2c499aD98a8ce58e58, "USDT"));
        
        // Arbitrum tokens
        chainTokens[ARBITRUM].push(TokenInfo(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1, "WETH"));
        chainTokens[ARBITRUM].push(TokenInfo(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, "USDC"));
        chainTokens[ARBITRUM].push(TokenInfo(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1, "DAI"));
        chainTokens[ARBITRUM].push(TokenInfo(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9, "USDT"));
    }
    
    function deployInnerChainContracts(
        address uniswapV2Router, 
        address uniswapV2Factory,
        address sushiswapRouter,
        address sushiswapFactory,
        address uniswapV3Router,
        address uniswapV3Factory,
        address uniswapV3Quoter,
        bool deployUniV2,
        bool deploySushi,
        bool deployUniV3
    ) internal returns (address registryAddress, address routerAddress) {
        vm.startBroadcast();
        
        // Deploy InnerChainRegistry
        InnerChainRegistry registry = new InnerChainRegistry();
        
        // Deploy DEX adapters based on parameters
        if (deployUniV2) {
            UniswapV2Adapter uniswapV2Adapter = new UniswapV2Adapter(uniswapV2Router, uniswapV2Factory);
            registry.addAdapter("UniswapV2", address(uniswapV2Adapter));
            console.log("Deployed UniswapV2Adapter at:", address(uniswapV2Adapter));
        }
        
        if (deploySushi) {
            SushiSwapAdapter sushiswapAdapter = new SushiSwapAdapter(sushiswapRouter, sushiswapFactory);
            registry.addAdapter("SushiSwap", address(sushiswapAdapter));
            console.log("Deployed SushiSwapAdapter at:", address(sushiswapAdapter));
        }
        
        if (deployUniV3) {
            UniswapV3Adapter uniswapV3Adapter = new UniswapV3Adapter(uniswapV3Router, uniswapV3Factory, uniswapV3Quoter);
            registry.addAdapter("UniswapV3", address(uniswapV3Adapter));
            console.log("Deployed UniswapV3Adapter at:", address(uniswapV3Adapter));
        }
        
        // Deploy InnerChainRouter
        InnerChainRouter router = new InnerChainRouter(registry);
        
        console.log("Deployed InnerChainRegistry at:", address(registry));
        console.log("Deployed InnerChainRouter at:", address(router));
        
        vm.stopBroadcast();
        
        return (address(registry), address(router));
    }
    
    function deployOuterChainContracts(
        address innerChainRouter,
        address axelarGateway,
        address axelarGasService
    ) internal returns (address registryAddress, address routerAddress) {
        vm.startBroadcast();
        
        // Deploy OuterChainRegistry
        OuterChainRegistry registry = new OuterChainRegistry();
        
        // Deploy OuterChainRouterAxelar
        OuterChainRouter router = new OuterChainRouter(
            innerChainRouter,
            address(registry),
            axelarGateway,
            axelarGasService
        );
        
        // Authorize the router to update the registry
        registry.setAuthorizedRouter(address(router), true);
        
        console.log("Deployed OuterChainRegistry at:", address(registry));
        console.log("Deployed OuterChainRouterAxelar at:", address(router));
        
        vm.stopBroadcast();
        
        return (address(registry), address(router));
    }
    
    function deployToEthereum() internal {
        console.log("\n--- Deploying to Ethereum ---");
        
        // Set the fork to Ethereum
        vm.selectFork(vm.createFork(vm.envString("ETH_RPC_URL")));
        
        // Deploy Inner Chain Contracts
        (address innerRegistryAddress, address innerRouterAddress) = deployInnerChainContracts(
            ETHEREUM_UNISWAP_V2_ROUTER,
            ETHEREUM_UNISWAP_V2_FACTORY,
            ETHEREUM_SUSHISWAP_ROUTER,
            ETHEREUM_SUSHISWAP_FACTORY,
            ETHEREUM_UNISWAP_V3_ROUTER,
            ETHEREUM_UNISWAP_V3_FACTORY,
            ETHEREUM_UNISWAP_V3_QUOTER,
            true, // Deploy UniswapV2
            true, // Deploy SushiSwap
            true  // Deploy UniswapV3
        );
        
        // Deploy Outer Chain Contracts
        (address outerRegistryAddress, address outerRouterAddress) = deployOuterChainContracts(
            innerRouterAddress,
            ETHEREUM_AXELAR_GATEWAY,
            ETHEREUM_AXELAR_GAS_SERVICE
        );
        
        // Store deployed addresses
        deployedAddresses[ETHEREUM_MAINNET] = DeployedContracts({
            innerChainRegistry: innerRegistryAddress,
            innerChainRouter: innerRouterAddress,
            outerChainRegistry: outerRegistryAddress,
            outerChainRouterAxelar: outerRouterAddress
        });
        
        // Store router address as string for cross-chain configuration
        routerAddressesString[ETHEREUM_MAINNET] = toAsciiString(outerRouterAddress);
    }
    
    function deployToOptimism() internal {
        console.log("\n--- Deploying to Optimism ---");
        
        // Set the fork to Optimism
        vm.selectFork(vm.createFork(vm.envString("OPTIMISM_RPC_URL")));
        
        // Deploy Inner Chain Contracts - Optimism has UniswapV3 but not UniswapV2
        (address innerRegistryAddress, address innerRouterAddress) = deployInnerChainContracts(
            address(0), // No UniswapV2 on Optimism
            address(0),
            address(0), // No SushiSwap on Optimism
            address(0),
            OPTIMISM_UNISWAP_V3_ROUTER,
            OPTIMISM_UNISWAP_V3_FACTORY,
            OPTIMISM_UNISWAP_V3_QUOTER,
            false, // Don't deploy UniswapV2
            false, // Don't deploy SushiSwap
            true   // Deploy UniswapV3
        );
        
        // Deploy Outer Chain Contracts
        (address outerRegistryAddress, address outerRouterAddress) = deployOuterChainContracts(
            innerRouterAddress,
            OPTIMISM_AXELAR_GATEWAY,
            OPTIMISM_AXELAR_GAS_SERVICE
        );
        
        // Store deployed addresses
        deployedAddresses[OPTIMISM] = DeployedContracts({
            innerChainRegistry: innerRegistryAddress,
            innerChainRouter: innerRouterAddress,
            outerChainRegistry: outerRegistryAddress,
            outerChainRouterAxelar: outerRouterAddress
        });
        
        // Store router address as string for cross-chain configuration
        routerAddressesString[OPTIMISM] = toAsciiString(outerRouterAddress);
    }
    
    function deployToArbitrum() internal {
        console.log("\n--- Deploying to Arbitrum ---");
        
        // Set the fork to Arbitrum
        vm.selectFork(vm.createFork(vm.envString("ARBITRUM_RPC_URL")));
        
        // Deploy Inner Chain Contracts
        (address innerRegistryAddress, address innerRouterAddress) = deployInnerChainContracts(
            address(0), // No UniswapV2 on Arbitrum
            address(0),
            ARBITRUM_SUSHISWAP_ROUTER,
            ARBITRUM_SUSHISWAP_FACTORY,
            ARBITRUM_UNISWAP_V3_ROUTER,
            ARBITRUM_UNISWAP_V3_FACTORY,
            ARBITRUM_UNISWAP_V3_QUOTER,
            false, // Don't deploy UniswapV2
            true,  // Deploy SushiSwap
            true   // Deploy UniswapV3
        );
        
        // Deploy Outer Chain Contracts
        (address outerRegistryAddress, address outerRouterAddress) = deployOuterChainContracts(
            innerRouterAddress,
            ARBITRUM_AXELAR_GATEWAY,
            ARBITRUM_AXELAR_GAS_SERVICE
        );
        
        // Store deployed addresses
        deployedAddresses[ARBITRUM] = DeployedContracts({
            innerChainRegistry: innerRegistryAddress,
            innerChainRouter: innerRouterAddress,
            outerChainRegistry: outerRegistryAddress,
            outerChainRouterAxelar: outerRouterAddress
        });
        
        // Store router address as string for cross-chain configuration
        routerAddressesString[ARBITRUM] = toAsciiString(outerRouterAddress);
    }
    
    function configureCrossChainSettings() internal {
        console.log("\n--- Configuring Cross-Chain Settings ---");
        
        // Configure Ethereum Registry
        configureRegistry(ETHEREUM_MAINNET, ETHEREUM_CHAIN_NAME);
        
        // Configure Optimism Registry
        configureRegistry(OPTIMISM, OPTIMISM_CHAIN_NAME);
        
        // Configure Arbitrum Registry
        configureRegistry(ARBITRUM, ARBITRUM_CHAIN_NAME);
    }
    
    function configureRegistry(uint32 chainId, string memory chainName) internal {
        DeployedContracts memory contracts = deployedAddresses[chainId];
        
        // Set the fork to the target chain
        if (chainId == ETHEREUM_MAINNET) {
            vm.selectFork(vm.createFork(vm.envString("ETH_RPC_URL")));
        } else if (chainId == OPTIMISM) {
            vm.selectFork(vm.createFork(vm.envString("OPTIMISM_RPC_URL")));
        } else if (chainId == ARBITRUM) {
            vm.selectFork(vm.createFork(vm.envString("ARBITRUM_RPC_URL")));
        }
        
        vm.startBroadcast();
        
        OuterChainRegistry registry = OuterChainRegistry(contracts.outerChainRegistry);
        
        // Configure chain names
        registry.setChainName(ETHEREUM_MAINNET, ETHEREUM_CHAIN_NAME);
        registry.setChainName(OPTIMISM, OPTIMISM_CHAIN_NAME);
        registry.setChainName(ARBITRUM, ARBITRUM_CHAIN_NAME);
        
        // Configure remote router addresses
        registry.setRemoteRouterAddress(ETHEREUM_CHAIN_NAME, routerAddressesString[ETHEREUM_MAINNET]);
        registry.setRemoteRouterAddress(OPTIMISM_CHAIN_NAME, routerAddressesString[OPTIMISM]);
        registry.setRemoteRouterAddress(ARBITRUM_CHAIN_NAME, routerAddressesString[ARBITRUM]);
        
        // Configure token symbols for this chain
        TokenInfo[] memory tokens = chainTokens[chainId];
        for (uint i = 0; i < tokens.length; i++) {
            registry.setTokenSymbol(tokens[i].tokenAddress, tokens[i].symbol);
        }
        
        vm.stopBroadcast();
        
        console.log("Configured cross-chain settings for chain ID:", chainId);
    }
    
    function deployToTestnets() public {
        // Deploy to Goerli
        deployToGoerli();
        
        // Deploy to Sepolia
        deployToSepolia();
        
        // Configure testnet cross-chain settings
        configureTestnetCrossChainSettings();
        
        // Log testnet deployment summary
        logTestnetDeploymentSummary();
    }
    
    function deployToGoerli() internal {
        console.log("\n--- Deploying to Goerli Testnet ---");
        
        // Set the fork to Goerli
        vm.selectFork(vm.createFork(vm.envString("GOERLI_RPC_URL")));
        
        // Deploy Inner Chain Contracts - Just UniswapV2 for simplicity
        (address innerRegistryAddress, address innerRouterAddress) = deployInnerChainContracts(
            GOERLI_UNISWAP_V2_ROUTER,
            GOERLI_UNISWAP_V2_FACTORY,
            address(0), // No SushiSwap
            address(0),
            address(0), // No UniswapV3
            address(0),
            address(0),
            true,  // Deploy UniswapV2
            false, // Don't deploy SushiSwap
            false  // Don't deploy UniswapV3
        );
        
        // Deploy Outer Chain Contracts
        (address outerRegistryAddress, address outerRouterAddress) = deployOuterChainContracts(
            innerRouterAddress,
            GOERLI_AXELAR_GATEWAY,
            GOERLI_AXELAR_GAS_SERVICE
        );
        
        // Store deployed addresses
        deployedAddresses[GOERLI] = DeployedContracts({
            innerChainRegistry: innerRegistryAddress,
            innerChainRouter: innerRouterAddress,
            outerChainRegistry: outerRegistryAddress,
            outerChainRouterAxelar: outerRouterAddress
        });
        
        // Store router address as string for cross-chain configuration
        routerAddressesString[GOERLI] = toAsciiString(outerRouterAddress);
    }
    
    function deployToSepolia() internal {
        console.log("\n--- Deploying to Sepolia Testnet ---");
        
        // Set the fork to Sepolia
        vm.selectFork(vm.createFork(vm.envString("SEPOLIA_RPC_URL")));
        
        // Deploy Inner Chain Contracts - Just UniswapV2 for simplicity (adjust as needed for Sepolia)
        (address innerRegistryAddress, address innerRouterAddress) = deployInnerChainContracts(
            GOERLI_UNISWAP_V2_ROUTER, // Use Goerli addresses for demonstration
            GOERLI_UNISWAP_V2_FACTORY,
            address(0), // No SushiSwap
            address(0),
            address(0), // No UniswapV3
            address(0),
            address(0),
            true,  // Deploy UniswapV2
            false, // Don't deploy SushiSwap
            false  // Don't deploy UniswapV3
        );
        
        // Deploy Outer Chain Contracts
        (address outerRegistryAddress, address outerRouterAddress) = deployOuterChainContracts(
            innerRouterAddress,
            SEPOLIA_AXELAR_GATEWAY,
            SEPOLIA_AXELAR_GAS_SERVICE
        );
        
        // Store deployed addresses
        deployedAddresses[SEPOLIA] = DeployedContracts({
            innerChainRegistry: innerRegistryAddress,
            innerChainRouter: innerRouterAddress,
            outerChainRegistry: outerRegistryAddress,
            outerChainRouterAxelar: outerRouterAddress
        });
        
        // Store router address as string for cross-chain configuration
        routerAddressesString[SEPOLIA] = toAsciiString(outerRouterAddress);
    }
    
    function configureTestnetCrossChainSettings() internal {
        console.log("\n--- Configuring Testnet Cross-Chain Settings ---");
        
        // Configure Goerli Registry
        configureTestnetRegistry(GOERLI, GOERLI_CHAIN_NAME);
        
        // Configure Sepolia Registry
        configureTestnetRegistry(SEPOLIA, SEPOLIA_CHAIN_NAME);
    }
    
    function configureTestnetRegistry(uint32 chainId, string memory chainName) internal {
        DeployedContracts memory contracts = deployedAddresses[chainId];
        
        // Set the fork to the target chain
        if (chainId == GOERLI) {
            vm.selectFork(vm.createFork(vm.envString("GOERLI_RPC_URL")));
        } else if (chainId == SEPOLIA) {
            vm.selectFork(vm.createFork(vm.envString("SEPOLIA_RPC_URL")));
        }
        
        vm.startBroadcast();
        
        OuterChainRegistry registry = OuterChainRegistry(contracts.outerChainRegistry);
        
        // Configure chain names
        registry.setChainName(GOERLI, GOERLI_CHAIN_NAME);
        registry.setChainName(SEPOLIA, SEPOLIA_CHAIN_NAME);
        
        // Configure remote router addresses
        registry.setRemoteRouterAddress(GOERLI_CHAIN_NAME, routerAddressesString[GOERLI]);
        registry.setRemoteRouterAddress(SEPOLIA_CHAIN_NAME, routerAddressesString[SEPOLIA]);
        
        // Configure test tokens (need to add test token addresses and symbols)
        // Example:
        // registry.setTokenSymbol(0xTESTtoken1, "USDC");
        // registry.setTokenSymbol(0xTESTtoken2, "DAI");
        
        vm.stopBroadcast();
        
        console.log("Configured testnet cross-chain settings for chain ID:", chainId);
    }
    
    function logDeploymentSummary() internal view {
        console.log("\n=== Deployment Summary ===");
        
        // Ethereum Summary
        console.log("\nEthereum (Chain ID: 1):");
        console.log("InnerChainRegistry:", deployedAddresses[ETHEREUM_MAINNET].innerChainRegistry);
        console.log("InnerChainRouter:", deployedAddresses[ETHEREUM_MAINNET].innerChainRouter);
        console.log("OuterChainRegistry:", deployedAddresses[ETHEREUM_MAINNET].outerChainRegistry);
        console.log("OuterChainRouterAxelar:", deployedAddresses[ETHEREUM_MAINNET].outerChainRouterAxelar);
        
        // Optimism Summary
        console.log("\nOptimism (Chain ID: 10):");
        console.log("InnerChainRegistry:", deployedAddresses[OPTIMISM].innerChainRegistry);
        console.log("InnerChainRouter:", deployedAddresses[OPTIMISM].innerChainRouter);
        console.log("OuterChainRegistry:", deployedAddresses[OPTIMISM].outerChainRegistry);
        console.log("OuterChainRouterAxelar:", deployedAddresses[OPTIMISM].outerChainRouterAxelar);
        
        // Arbitrum Summary
        console.log("\nArbitrum (Chain ID: 42161):");
        console.log("InnerChainRegistry:", deployedAddresses[ARBITRUM].innerChainRegistry);
        console.log("InnerChainRouter:", deployedAddresses[ARBITRUM].innerChainRouter);
        console.log("OuterChainRegistry:", deployedAddresses[ARBITRUM].outerChainRegistry);
        console.log("OuterChainRouterAxelar:", deployedAddresses[ARBITRUM].outerChainRouterAxelar);
    }
    
    function logTestnetDeploymentSummary() internal view {
        console.log("\n=== Testnet Deployment Summary ===");
        
        // Goerli Summary
        console.log("\nGoerli (Chain ID: 5):");
        console.log("InnerChainRegistry:", deployedAddresses[GOERLI].innerChainRegistry);
        console.log("InnerChainRouter:", deployedAddresses[GOERLI].innerChainRouter);
        console.log("OuterChainRegistry:", deployedAddresses[GOERLI].outerChainRegistry);
        console.log("OuterChainRouterAxelar:", deployedAddresses[GOERLI].outerChainRouterAxelar);
        
        // Sepolia Summary
        console.log("\nSepolia (Chain ID: 11155111):");
        console.log("InnerChainRegistry:", deployedAddresses[SEPOLIA].innerChainRegistry);
        console.log("InnerChainRouter:", deployedAddresses[SEPOLIA].innerChainRouter);
        console.log("OuterChainRegistry:", deployedAddresses[SEPOLIA].outerChainRegistry);
        console.log("OuterChainRouterAxelar:", deployedAddresses[SEPOLIA].outerChainRouterAxelar);
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