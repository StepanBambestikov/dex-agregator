// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/OuterChainRouter.sol";
import "../src/OuterChainRegistry.sol";
import "../src/InnerChainRouter.sol";
import "./mocks/MockInnerChainRouter.sol";
import "./mocks/MockAlexaeGasService.sol";
import "./mocks/MockAlexarGateway.sol";
import "./mocks/MockERC20.sol";

contract OuterChainRouterAxelarTest is Test {
    OuterChainRouter public router;
    OuterChainRegistry public registry;
    MockInnerChainRouter public innerRouter;
    MockAxelarGateway public axelarGateway;
    MockAxelarGasService public axelarGasService;
    
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    MockERC20 public tokenC;
    
    address public owner;
    address public user;
    
    uint8 public constant SWAP_COMMAND = 1;
    uint8 public constant CROSS_CHAIN_COMMAND = 2;
    
    // Тестовые данные
    uint32 public constant ETHEREUM_CHAIN_ID = 1;
    uint32 public constant POLYGON_CHAIN_ID = 137;
    string public constant ETHEREUM_CHAIN_NAME = "Ethereum";
    string public constant POLYGON_CHAIN_NAME = "Polygon";
    string public constant REMOTE_ROUTER_ADDRESS = "0x1234567890123456789012345678901234567890";
    
    // События для проверки
    event SwapExecuted(
        address indexed sender,
        string dexName,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address recipient
    );
    
    event CrossChainTransferInitiated(
        address indexed sender,
        string destinationChain,
        address indexed token,
        uint256 amount,
        bytes destinationAddress
    );
    
    function setUp() public {
        owner = address(this);
        user = address(0x123);
        
        // Создаем мок-токены
        tokenA = new MockERC20("Token A", "TOKENA");
        tokenB = new MockERC20("Token B", "TOKENB");
        tokenC = new MockERC20("Token C", "TOKENC");
        
        // Минтим токены пользователю для тестов
        tokenA.mint(user, 1000 ether);
        tokenB.mint(user, 1000 ether);
        tokenC.mint(user, 1000 ether);
        
        // Создаем и настраиваем мок-контракты
        innerRouter = new MockInnerChainRouter();
        axelarGateway = new MockAxelarGateway();
        axelarGasService = new MockAxelarGasService();
        
        // Создаем и настраиваем реестр
        registry = new OuterChainRegistry();
        
        // Настраиваем реестр
        registry.setChainName(ETHEREUM_CHAIN_ID, ETHEREUM_CHAIN_NAME);
        registry.setChainName(POLYGON_CHAIN_ID, POLYGON_CHAIN_NAME);
        registry.setTokenSymbol(address(tokenA), "TOKENA");
        registry.setTokenSymbol(address(tokenB), "TOKENB");
        registry.setTokenSymbol(address(tokenC), "TOKENC");
        registry.setRemoteRouterAddress(POLYGON_CHAIN_NAME, REMOTE_ROUTER_ADDRESS);
        
        // Создаем основной тестируемый контракт
        router = new OuterChainRouter(
            address(innerRouter),
            address(registry),
            address(axelarGateway),
            address(axelarGasService)
        );
        
        // Настраиваем axelarGateway для распознавания токенов
        axelarGateway.setTokenAddress("TOKENA", address(tokenA));
        axelarGateway.setTokenAddress("TOKENB", address(tokenB));
        axelarGateway.setTokenAddress("TOKENC", address(tokenC));
        
        // Устанавливаем ожидаемое возвращаемое значение для swap
        innerRouter.setSwapReturnAmount(0.9 ether);
        
        // Даем разрешения для тестов
        vm.startPrank(user);
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        tokenC.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }
    
    // Вспомогательная функция для создания команды свапа
    function createSwapCommand(
        string memory dexName,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) public pure returns (bytes memory) {
        OuterChainRouter.SwapCommand memory cmd = OuterChainRouter.SwapCommand(
            dexName,
            tokenIn,
            tokenOut,
            amountIn,
            amountOutMin,
            recipient
        );
        
        bytes memory encodedCmd = abi.encode(cmd);
        bytes memory result = new bytes(1 + encodedCmd.length);
        
        result[0] = bytes1(SWAP_COMMAND);
        
        for (uint256 i = 0; i < encodedCmd.length; i++) {
            result[i + 1] = encodedCmd[i];
        }
        
        return result;
    }
    
    // Вспомогательная функция для создания команды кросс-чейн
    function createCrossChainCommand(
        uint32 destinationChainId,
        address tokenToSend,
        uint256 amount,
        bytes memory destinationAddress,
        bytes memory extraData
    ) public pure returns (bytes memory) {
        OuterChainRouter.CrossChainCommand memory cmd = OuterChainRouter.CrossChainCommand(
            destinationChainId,
            tokenToSend,
            amount,
            destinationAddress,
            extraData
        );
        
        bytes memory encodedCmd = abi.encode(cmd);
        bytes memory result = new bytes(1 + encodedCmd.length);
        
        result[0] = bytes1(CROSS_CHAIN_COMMAND);
        
        for (uint256 i = 0; i < encodedCmd.length; i++) {
            result[i + 1] = encodedCmd[i];
        }
        
        return result;
    }

    // Тест для функциональности executeCommands с одной swap-командой
    function testExecuteCommandsWithSwap() public {
        // Создаем команду свапа
        bytes memory swapCmd = createSwapCommand(
            "Uniswap",
            address(tokenA),
            address(tokenB),
            1 ether,
            0.9 ether,
            user
        );
        
        bytes[] memory commands = new bytes[](1);
        commands[0] = swapCmd;
        
        // Проверяем баланс перед выполнением
        assertEq(tokenA.balanceOf(user), 1000 ether);
        
        vm.expectEmit(true, true, true, true);
        emit SwapExecuted(
            user,
            "Uniswap",
            address(tokenA),
            address(tokenB),
            1 ether,
            0.9 ether,
            user
        );
        
        // Выполняем команды от имени пользователя
        vm.prank(user);
        router.executeCommands(commands);
        
        // Проверяем, что токены были переведены с аккаунта пользователя
        assertEq(tokenA.balanceOf(user), 999 ether);
    }
    
    // Тест для функциональности executeCommands с кросс-чейн командой
    function testExecuteCommandsWithCrossChain() public {
        // Адрес получателя в целевой сети
        bytes memory receiverAddress = bytes("0x0000000000000000000000000000000000000abc");
        
        // Создаем команду кросс-чейн
        bytes memory crossChainCmd = createCrossChainCommand(
            POLYGON_CHAIN_ID,
            address(tokenC),
            2 ether,
            receiverAddress,
            bytes("")
        );
        
        bytes[] memory commands = new bytes[](1);
        commands[0] = crossChainCmd;
        
        // Проверяем баланс перед выполнением
        assertEq(tokenC.balanceOf(user), 1000 ether);
        
        vm.expectEmit(true, true, true, true);
        emit CrossChainTransferInitiated(
            user,
            POLYGON_CHAIN_NAME,
            address(tokenC),
            2 ether,
            receiverAddress
        );
        
        // Выполняем команды от имени пользователя с передачей ETH для газа
        vm.prank(user);
        router.executeCommands{value: 0.01 ether}(commands);
        
        // Проверяем, что токены были переведены с аккаунта пользователя
        assertEq(tokenC.balanceOf(user), 998 ether);
    }
    
    // Тест для функциональности executeCommands с последовательностью команд
    function testExecuteCommandsWithSequence() public {
        // Создаем команду свапа
        bytes memory swapCmd = createSwapCommand(
            "Uniswap",
            address(tokenA),
            address(tokenB),
            1 ether,
            0.9 ether,
            user
        );
        
        // Адрес получателя в целевой сети
        bytes memory receiverAddress = bytes("0x0000000000000000000000000000000000000abc");
        
        // Создаем команду кросс-чейн
        bytes memory crossChainCmd = createCrossChainCommand(
            POLYGON_CHAIN_ID,
            address(tokenC),
            2 ether,
            receiverAddress,
            bytes("")
        );
        
        // Создаем вторую команду свапа, которая не должна быть выполнена в этой сети
        bytes memory swapCmd2 = createSwapCommand(
            "Sushiswap",
            address(tokenB),
            address(tokenA),
            0.5 ether,
            0.45 ether,
            user
        );
        
        // Собираем последовательность команд
        bytes[] memory commands = new bytes[](3);
        commands[0] = swapCmd;
        commands[1] = crossChainCmd;
        commands[2] = swapCmd2;
        
        // Проверяем балансы перед выполнением
        assertEq(tokenA.balanceOf(user), 1000 ether);
        assertEq(tokenC.balanceOf(user), 1000 ether);
        
        // Ожидаем события для свапа и кросс-чейн команды
        vm.expectEmit(true, true, true, true);
        emit SwapExecuted(
            user,
            "Uniswap",
            address(tokenA),
            address(tokenB),
            1 ether,
            0.9 ether,
            user
        );
        
        vm.expectEmit(true, true, true, true);
        emit CrossChainTransferInitiated(
            user,
            POLYGON_CHAIN_NAME,
            address(tokenC),
            2 ether,
            receiverAddress
        );
        
        // Выполняем команды от имени пользователя с передачей ETH для газа
        vm.prank(user);
        router.executeCommands{value: 0.01 ether}(commands);
        
        // Проверяем, что токены были переведены с аккаунта пользователя
        assertEq(tokenA.balanceOf(user), 999 ether);
        assertEq(tokenC.balanceOf(user), 998 ether);
        
        
    }
    
    // Тест для функциональности executeWithToken (получение токенов из другой сети)
    function testExecuteWithToken() public {
        // Создаем команду свапа, которая будет выполнена в этой сети после получения токенов
        bytes memory swapCmd = createSwapCommand(
            "Uniswap",
            address(tokenA), // Этот адрес будет заменен на реальный адрес токена при выполнении
            address(tokenB),
            3 ether, // Эта сумма будет заменена на реальную сумму при выполнении
            2.7 ether, // Минимальная сумма должна быть актуальной
            user
        );
        
        // Собираем команды для отправки
        bytes[] memory commands = new bytes[](1);
        commands[0] = swapCmd;
        
        // Создаем payload, как если бы он был отправлен из другой сети
        bytes memory payload = abi.encode(bytes("destination_address"), commands);
        
        // Минтим токены на axelarGateway для имитации получения из другой сети
        tokenA.mint(address(axelarGateway), 3 ether);
        
        // Даем разрешение аксилари шлюзу на использование токенов роутером
        vm.prank(address(axelarGateway));
        tokenA.approve(address(router), 3 ether);
        
        // Вызываем executeWithToken от имени axelarGateway
        vm.prank(address(axelarGateway));
        router.executeWithToken(
            POLYGON_CHAIN_NAME,
            REMOTE_ROUTER_ADDRESS,
            payload,
            "TOKENA",
            3 ether
        );
        
        // Проверяем, что токены были обработаны
        // В реальности здесь нужна более сложная проверка, зависящая от логики executeWithToken
    }
    
    // Тест на ошибку при вызове executeWithToken не от axelarGateway
    function testExecuteWithTokenNotFromGateway() public {
        bytes memory payload = abi.encode(bytes("destination_address"), new bytes[](0));
        
        vm.expectRevert();
        router.executeWithToken(
            ETHEREUM_CHAIN_NAME,
            REMOTE_ROUTER_ADDRESS,
            payload,
            "TOKENA",
            1 ether
        );
    }
    
    // Тест на ошибку при вызове executeWithToken с неизвестного источника
    function testExecuteWithTokenFromUnknownSource() public {
        bytes memory payload = abi.encode(bytes("destination_address"), new bytes[](0));
        
        // Вызываем executeWithToken с неизвестным sourceAddress, должна быть ошибка
        vm.prank(address(axelarGateway));
        vm.expectRevert();
        router.executeWithToken(
            ETHEREUM_CHAIN_NAME,
            "0xunknownAddress",
            payload,
            "TOKENA",
            1 ether
        );
    }
}