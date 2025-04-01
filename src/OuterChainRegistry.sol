// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract OuterChainRegistry is Ownable, Pausable {
    // Маппинг ID чейна к строке с названием чейна (для Axelar)
    mapping(uint32 => string) public chainIdToChainName;
    
    // Маппинг адреса токена к его символу (для Axelar)
    mapping(address => string) public tokenAddressToSymbol;
    
    // Обратный маппинг символа токена к его адресу
    mapping(string => address) public symbolToTokenAddress;
    
    // Маппинг названия чейна к адресу контракта (для Axelar)
    mapping(string => string) public remoteRouterAddresses;
    
    // Маппинг авторизованных мостов
    mapping(address => bool) public authorizedBridges;
    
    // Маппинг авторизованных роутеров, которые могут обновлять хранилище
    mapping(address => bool) public authorizedRouters;
    
    // События
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
    
    /**
     * @dev Установка авторизации для роутера
     * @param router Адрес роутера
     * @param isAuthorized Флаг авторизации
     */
    function setAuthorizedRouter(address router, bool isAuthorized) external onlyOwner {
        authorizedRouters[router] = isAuthorized;
        emit RouterAuthorizationChanged(router, isAuthorized);
    }
    
    /**
     * @dev Настройка маппинга чейн ID к названию сети
     * @param chainId ID цепи
     * @param chainName Название цепи для Axelar
     */
    function setChainName(uint32 chainId, string calldata chainName) external onlyAuthorizedRouter {
        require(bytes(chainName).length > 0, "Chain name cannot be empty");
        chainIdToChainName[chainId] = chainName;
        emit ChainNameSet(chainId, chainName);
    }
    
    /**
     * @dev Групповая настройка маппинга чейн ID к названию сети
     * @param chainIds Массив ID цепей
     * @param chainNames Массив названий цепей
     */
    function batchSetChainNames(uint32[] calldata chainIds, string[] calldata chainNames) external onlyAuthorizedRouter {
        require(chainIds.length == chainNames.length, "Arrays length mismatch");
        for (uint256 i = 0; i < chainIds.length; i++) {
            require(bytes(chainNames[i]).length > 0, "Chain name cannot be empty");
            chainIdToChainName[chainIds[i]] = chainNames[i];
            emit ChainNameSet(chainIds[i], chainNames[i]);
        }
    }
    
    /**
     * @dev Настройка маппинга токен адреса к символу
     * @param tokenAddress Адрес токена
     * @param symbol Символ токена
     */
    function setTokenSymbol(address tokenAddress, string calldata symbol) external onlyAuthorizedRouter {
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(bytes(symbol).length > 0, "Symbol cannot be empty");
        tokenAddressToSymbol[tokenAddress] = symbol;
        symbolToTokenAddress[symbol] = tokenAddress;
        emit TokenSymbolSet(tokenAddress, symbol);
    }
    
    /**
     * @dev Групповая настройка маппинга токен адреса к символу
     * @param tokenAddresses Массив адресов токенов
     * @param symbols Массив символов токенов
     */
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
    
    /**
     * @dev Настройка маппинга адресов удаленных контрактов по названию сети
     * @param chainName Название цепи
     * @param routerAddress Адрес роутера в указанной цепи
     */
    function setRemoteRouterAddress(string calldata chainName, string calldata routerAddress) external onlyAuthorizedRouter {
        require(bytes(chainName).length > 0, "Chain name cannot be empty");
        require(bytes(routerAddress).length > 0, "Router address cannot be empty");
        remoteRouterAddresses[chainName] = routerAddress;
        emit RemoteRouterSet(chainName, routerAddress);
    }
    
    /**
     * @dev Групповая настройка маппинга адресов удаленных контрактов
     * @param chainNames Массив названий цепей
     * @param routerAddresses Массив адресов роутеров
     */
    function batchSetRemoteRouterAddresses(string[] calldata chainNames, string[] calldata routerAddresses) external onlyAuthorizedRouter {
        require(chainNames.length == routerAddresses.length, "Arrays length mismatch");
        for (uint256 i = 0; i < chainNames.length; i++) {
            require(bytes(chainNames[i]).length > 0, "Chain name cannot be empty");
            require(bytes(routerAddresses[i]).length > 0, "Router address cannot be empty");
            remoteRouterAddresses[chainNames[i]] = routerAddresses[i];
            emit RemoteRouterSet(chainNames[i], routerAddresses[i]);
        }
    }
    
    /**
     * @dev Настройка авторизованных мостов
     * @param bridge Адрес моста
     * @param isAuthorized Флаг авторизации
     */
    function setAuthorizedBridge(address bridge, bool isAuthorized) external onlyAuthorizedRouter {
        require(bridge != address(0), "Bridge address cannot be zero");
        authorizedBridges[bridge] = isAuthorized;
        emit BridgeAuthorizationChanged(bridge, isAuthorized);
    }
    
    /**
     * @dev Групповая настройка авторизованных мостов
     * @param bridges Массив адресов мостов
     * @param isAuthorized Массив флагов авторизации
     */
    function batchSetAuthorizedBridges(address[] calldata bridges, bool[] calldata isAuthorized) external onlyAuthorizedRouter {
        require(bridges.length == isAuthorized.length, "Arrays length mismatch");
        for (uint256 i = 0; i < bridges.length; i++) {
            require(bridges[i] != address(0), "Bridge address cannot be zero");
            authorizedBridges[bridges[i]] = isAuthorized[i];
            emit BridgeAuthorizationChanged(bridges[i], isAuthorized[i]);
        }
    }
    
    /**
     * @dev Получение названия цепи по ID
     * @param chainId ID цепи
     * @return Название цепи
     */
    function getChainName(uint32 chainId) external view returns (string memory) {
        return chainIdToChainName[chainId];
    }
    
    /**
     * @dev Получение символа токена по адресу
     * @param tokenAddress Адрес токена
     * @return Символ токена
     */
    function getTokenSymbol(address tokenAddress) external view returns (string memory) {
        return tokenAddressToSymbol[tokenAddress];
    }
    
    /**
     * @dev Получение адреса токена по символу
     * @param symbol Символ токена
     * @return Адрес токена
     */
    function getTokenAddress(string calldata symbol) external view returns (address) {
        return symbolToTokenAddress[symbol];
    }
    
    /**
     * @dev Получение адреса удаленного роутера по названию цепи
     * @param chainName Название цепи
     * @return Адрес роутера
     */
    function getRemoteRouterAddress(string calldata chainName) external view returns (string memory) {
        return remoteRouterAddresses[chainName];
    }
    
    /**
     * @dev Проверка авторизации моста
     * @param bridge Адрес моста
     * @return Флаг авторизации
     */
    function isBridgeAuthorized(address bridge) external view returns (bool) {
        return authorizedBridges[bridge];
    }
    
    /**
     * @dev Приостановить контракт (только владелец)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Возобновить контракт (только владелец)
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}