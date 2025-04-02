// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

//The contract is used to store all the states needed for routing within a bunch of blockchain.
// The functionality involves storing addresses on a specific network for tokens
// that can be transferred between blockchains, authorized bridges,
// and router addresses on other networks that can send commands.
contract OuterChainRegistry is Ownable, Pausable {
    mapping(uint32 => string) public chainIdToChainName;
    
    mapping(address => string) public tokenAddressToSymbol;
    
    mapping(string => address) public symbolToTokenAddress;
    
    mapping(string => string) public remoteRouterAddresses;
    
    mapping(address => bool) public authorizedBridges;
    
    mapping(address => bool) public authorizedRouters;
    
    event ChainNameSet(uint32 indexed chainId, string chainName);
    event TokenSymbolSet(address indexed tokenAddress, string symbol);
    event RemoteRouterSet(string chainName, string routerAddress);
    event BridgeAuthorizationChanged(address indexed bridge, bool isAuthorized);
    event RouterAuthorizationChanged(address indexed router, bool isAuthorized);
    
    constructor() Ownable(msg.sender) {
    }
    
    modifier onlyAuthorizedRouter() {
        require(authorizedRouters[msg.sender] || msg.sender == owner(), "Caller is not an authorized router");
        _;
    }
    
    function setAuthorizedRouter(address router, bool isAuthorized) external onlyOwner {
        authorizedRouters[router] = isAuthorized;
        emit RouterAuthorizationChanged(router, isAuthorized);
    }
    
    function setChainName(uint32 chainId, string calldata chainName) external onlyAuthorizedRouter {
        require(bytes(chainName).length > 0, "Chain name cannot be empty");
        chainIdToChainName[chainId] = chainName;
        emit ChainNameSet(chainId, chainName);
    }
    
    function batchSetChainNames(uint32[] calldata chainIds, string[] calldata chainNames) external onlyAuthorizedRouter {
        require(chainIds.length == chainNames.length, "Arrays length mismatch");
        for (uint256 i = 0; i < chainIds.length; i++) {
            require(bytes(chainNames[i]).length > 0, "Chain name cannot be empty");
            chainIdToChainName[chainIds[i]] = chainNames[i];
            emit ChainNameSet(chainIds[i], chainNames[i]);
        }
    }
    
    function setTokenSymbol(address tokenAddress, string calldata symbol) external onlyAuthorizedRouter {
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(bytes(symbol).length > 0, "Symbol cannot be empty");
        tokenAddressToSymbol[tokenAddress] = symbol;
        symbolToTokenAddress[symbol] = tokenAddress;
        emit TokenSymbolSet(tokenAddress, symbol);
    }
    
    function batchSetTokenSymbols(address[] calldata tokenAddresses, string[] calldata symbols) external onlyAuthorizedRouter {
        require(tokenAddresses.length == symbols.length, "Arrays length mismatch");
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            require(tokenAddresses[i] != address(0), "Token address cannot be zero");
            require(bytes(symbols[i]).length > 0, "Symbol cannot be empty");
            tokenAddressToSymbol[tokenAddresses[i]] = symbols[i];
            symbolToTokenAddress[symbols[i]] = tokenAddresses[i];
            emit TokenSymbolSet(tokenAddresses[i], symbols[i]);
        }
    }
    
    function setRemoteRouterAddress(string calldata chainName, string calldata routerAddress) external onlyAuthorizedRouter {
        require(bytes(chainName).length > 0, "Chain name cannot be empty");
        require(bytes(routerAddress).length > 0, "Router address cannot be empty");
        remoteRouterAddresses[chainName] = routerAddress;
        emit RemoteRouterSet(chainName, routerAddress);
    }
    
    function batchSetRemoteRouterAddresses(string[] calldata chainNames, string[] calldata routerAddresses) external onlyAuthorizedRouter {
        require(chainNames.length == routerAddresses.length, "Arrays length mismatch");
        for (uint256 i = 0; i < chainNames.length; i++) {
            require(bytes(chainNames[i]).length > 0, "Chain name cannot be empty");
            require(bytes(routerAddresses[i]).length > 0, "Router address cannot be empty");
            remoteRouterAddresses[chainNames[i]] = routerAddresses[i];
            emit RemoteRouterSet(chainNames[i], routerAddresses[i]);
        }
    }
    
    function setAuthorizedBridge(address bridge, bool isAuthorized) external onlyAuthorizedRouter {
        require(bridge != address(0), "Bridge address cannot be zero");
        authorizedBridges[bridge] = isAuthorized;
        emit BridgeAuthorizationChanged(bridge, isAuthorized);
    }
    
    function batchSetAuthorizedBridges(address[] calldata bridges, bool[] calldata isAuthorized) external onlyAuthorizedRouter {
        require(bridges.length == isAuthorized.length, "Arrays length mismatch");
        for (uint256 i = 0; i < bridges.length; i++) {
            require(bridges[i] != address(0), "Bridge address cannot be zero");
            authorizedBridges[bridges[i]] = isAuthorized[i];
            emit BridgeAuthorizationChanged(bridges[i], isAuthorized[i]);
        }
    }
    
    function getChainName(uint32 chainId) external view returns (string memory) {
        return chainIdToChainName[chainId];
    }
    
    function getTokenSymbol(address tokenAddress) external view returns (string memory) {
        return tokenAddressToSymbol[tokenAddress];
    }
    
    function getTokenAddress(string calldata symbol) external view returns (address) {
        return symbolToTokenAddress[symbol];
    }
    
    function getRemoteRouterAddress(string calldata chainName) external view returns (string memory) {
        return remoteRouterAddresses[chainName];
    }
    
    function isBridgeAuthorized(address bridge) external view returns (bool) {
        return authorizedBridges[bridge];
    }
}