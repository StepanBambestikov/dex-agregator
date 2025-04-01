// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/OuterChainRouter.sol";
import "../src/OuterChainRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Скрипт для тестирования кросс-чейн функциональности.
 * Предполагается, что контракты уже развернуты в соответствующих сетях,
 * и адреса нужно будет указать при запуске скрипта.
 */
contract CrossChainTest is Script {
    // Axelar не имеет мгновенного финального подтверждения, и может потребоваться
    // время для завершения кросс-чейн транзакций. Это тестовый скрипт, который
    // позволяет отправить токены из одной цепи в другую.
    
    function testCrossChainTransfer(
        address sourceRouter,     // Адрес OuterChainRouterAxelar в исходной цепи
        address targetChainId,    // ID целевой цепи
        address tokenToSend,      // Адрес токена для отправки
        uint256 amount,           // Количество токенов для отправки
        address recipient         // Адрес получателя в целевой цепи
    ) public {
        vm.startBroadcast();
        
        // Создаем команду для кросс-чейн перевода
        OuterChainRouter.CrossChainCommand memory command = OuterChainRouter.CrossChainCommand({
            destinationChainId: uint32(uint160(targetChainId)), // Преобразуем в uint32
            tokenToSend: tokenToSend,
            amount: amount,
            destinationAddress: abi.encodePacked(recipient),
            extraData: bytes("")
        });
        
        // Упаковываем команду в байты
        bytes memory commandBytes = abi.encodePacked(
            uint8(2), // 2 = CROSS_CHAIN_COMMAND
            abi.encode(command)
        );
        
        // Создаем массив команд
        bytes[] memory commands = new bytes[](1);
        commands[0] = commandBytes;
        
        // Аппрув токенов для контракта роутера
        IERC20(tokenToSend).approve(sourceRouter, amount);
        
        // Рассчитываем необходимое количество газа для кросс-чейн операции
        // Для тестовых целей отправляем 0.01 ETH
        uint256 gasFee = 0.01 ether;
        
        // Вызываем метод executeCommands на роутере
        OuterChainRouter(payable(address(sourceRouter))).executeCommands{value: gasFee}(commands);
        
        console.log("Cross-chain transfer initiated");
        console.log("Token:", tokenToSend);
        console.log("Amount:", amount);
        console.log("Recipient:", recipient);
        console.log("Gas fee paid:", gasFee);
        
        vm.stopBroadcast();
    }
    
    // Пример использования на тестовой сети Goerli -> Arbitrum Goerli
    function testGoerliToArbitrumGoerli(
        address sourceRouter,
        address tokenToSend,
        address recipient
    ) public {
        // Предполагаем, что у отправителя есть 0.1 токена (с 18 decimals)
        uint256 amount = 0.1 * 10**18;
        
        // Arbitrum Goerli имеет chainId 421613
        address targetChainId = address(uint160(421613));
        
        testCrossChainTransfer(
            sourceRouter,
            targetChainId,
            tokenToSend,
            amount,
            recipient
        );
    }
    
    // Проверка настройки кросс-чейн регистров
    function verifyRegistryConfiguration(
        address registryAddress,
        uint32 remoteChainId,
        string memory expectedChainName,
        string memory expectedRouterAddress
    ) public view returns (bool) {
        OuterChainRegistry registry = OuterChainRegistry(registryAddress);
        
        string memory chainName = registry.getChainName(remoteChainId);
        string memory routerAddress = registry.getRemoteRouterAddress(chainName);
        
        console.log("Expected chain name:", expectedChainName);
        console.log("Actual chain name:", chainName);
        console.log("Expected router address:", expectedRouterAddress);
        console.log("Actual router address:", routerAddress);
        
        bool chainNameMatches = keccak256(abi.encodePacked(chainName)) == 
                                keccak256(abi.encodePacked(expectedChainName));
                                
        bool routerAddressMatches = keccak256(abi.encodePacked(routerAddress)) == 
                                    keccak256(abi.encodePacked(expectedRouterAddress));
                                    
        return chainNameMatches && routerAddressMatches;
    }
    
    // Проверка регистрации токенов
    function verifyTokenRegistration(
        address registryAddress,
        address tokenAddress,
        string memory expectedSymbol
    ) public view returns (bool) {
        OuterChainRegistry registry = OuterChainRegistry(registryAddress);
        
        string memory symbol = registry.getTokenSymbol(tokenAddress);
        address retrievedAddress = registry.getTokenAddress(symbol);
        
        console.log("Token address:", tokenAddress);
        console.log("Expected symbol:", expectedSymbol);
        console.log("Actual symbol:", symbol);
        console.log("Retrieved address:", retrievedAddress);
        
        bool symbolMatches = keccak256(abi.encodePacked(symbol)) == 
                            keccak256(abi.encodePacked(expectedSymbol));
                            
        bool addressMatches = retrievedAddress == tokenAddress;
        
        return symbolMatches && addressMatches;
    }
}