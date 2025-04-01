// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./InnerChainRouter.sol";
import "./OuterChainRegistry.sol";
import "./IInnerRouter.sol";
import "forge-std/console.sol";

// Интерфейс для Axelar Gateway
interface IAxelarGateway {
    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;
    
    function tokenAddresses(string calldata symbol) external view returns (address);
}

interface IAxelarGasService {
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;
}

contract OuterChainRouter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Внутренние контракты
    IInnerRouter public innerChainRouter;
    OuterChainRegistry public storage_;
    
    // Axelar контракты
    IAxelarGateway public axelarGateway;
    IAxelarGasService public axelarGasService;
    
    // Константы типов команд
    uint8 public constant SWAP_COMMAND = 1;
    uint8 public constant CROSS_CHAIN_COMMAND = 2;
    
    struct SwapCommand {
        string dexName;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        address recipient;
    }
    
    struct CrossChainCommand {
        uint32 destinationChainId;
        address tokenToSend;
        uint256 amount;
        bytes destinationAddress;
        bytes extraData;
    }
    
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
    
    event CommandsReceived(
        string indexed sourceChain,
        string indexed sourceAddress,
        uint256 commandsCount
    );

    constructor(
        address _innerChainRouter,
        address _storage,
        address _axelarGateway,
        address _axelarGasService
    ) Ownable(msg.sender) {
        innerChainRouter = IInnerRouter(_innerChainRouter);
        storage_ = OuterChainRegistry(_storage);
        axelarGateway = IAxelarGateway(_axelarGateway);
        axelarGasService = IAxelarGasService(_axelarGasService);
    }
    
    function setStorageContract(address _storage) external onlyOwner {
        require(_storage != address(0), "Storage address cannot be zero");
        storage_ = OuterChainRegistry(_storage);
    }
    
    function executeSwapCommand(SwapCommand memory command) internal returns (uint256 amountOut) {
        IERC20(command.tokenIn).safeTransferFrom(
            msg.sender, 
            address(this), 
            command.amountIn
        );
        IERC20(command.tokenIn).approve(address(innerChainRouter), command.amountIn);
        
        amountOut = innerChainRouter.swap(
            command.dexName,
            command.tokenIn,
            command.tokenOut,
            command.amountIn,
            command.amountOutMin,
            command.recipient
        );
        
        emit SwapExecuted(
            msg.sender,
            command.dexName,
            command.tokenIn,
            command.tokenOut,
            command.amountIn,
            amountOut,
            command.recipient
        );
        
        return amountOut;
    }
    
    function executeCrossChainCommand(CrossChainCommand memory command, bytes[] memory residueCommands) internal {
        string memory destinationChain = storage_.getChainName(command.destinationChainId);
        require(bytes(destinationChain).length > 0, "Destination chain not configured");
        
        string memory destinationRouterAddress = storage_.getRemoteRouterAddress(destinationChain);
        require(bytes(destinationRouterAddress).length > 0, "Destination router not configured");
        
        string memory tokenSymbol = storage_.getTokenSymbol(command.tokenToSend);
        require(bytes(tokenSymbol).length > 0, "Token symbol not configured");
        
        // Переводим токены от пользователя на контракт
        IERC20(command.tokenToSend).safeTransferFrom(
            msg.sender, 
            address(this), 
            command.amount
        );

        IERC20(command.tokenToSend).approve(address(axelarGateway), command.amount);
        bytes memory payload = abi.encode(command.destinationAddress, residueCommands);
        
        axelarGasService.payNativeGasForContractCallWithToken{value: msg.value}(
            address(this),
            destinationChain,
            destinationRouterAddress,
            payload,
            tokenSymbol,
            command.amount,
            msg.sender
        );

        axelarGateway.callContractWithToken(
            destinationChain,
            destinationRouterAddress,
            payload,
            tokenSymbol,
            command.amount
        );
        
        emit CrossChainTransferInitiated(
            msg.sender,
            destinationChain,
            command.tokenToSend,
            command.amount,
            command.destinationAddress
        );
    }
    
    function executeCommands(bytes[] memory commands) public payable { //TODO must be private
        for (uint256 i = 0; i < commands.length; i++) {
            bytes memory command = commands[i];
            require(command.length > 0, "Empty command");

            uint8 commandType = _getCommandType(command);
            bytes memory commandData = _getCommandData(command);
            
            if (commandType == SWAP_COMMAND) {
                SwapCommand memory swapCommand = abi.decode(commandData, (SwapCommand));
                executeSwapCommand(swapCommand);
            } else if (commandType == CROSS_CHAIN_COMMAND) {
                CrossChainCommand memory crossChainCommand = abi.decode(commandData, (CrossChainCommand));
                
                bytes[] memory residueCommands = new bytes[](commands.length - i - 1);
                for (uint256 j = 0; j < residueCommands.length; j++) {
                    residueCommands[j] = commands[i + j + 1];
                }
                
                executeCrossChainCommand(crossChainCommand, residueCommands);
                break;
            } else {
                revert("Unknown command type");
            }
        }
    }

    function executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external nonReentrant {
        require(msg.sender == address(axelarGateway), "Only gateway can execute");

        string memory expectedSourceAddress = storage_.getRemoteRouterAddress(sourceChain);
        require(
            keccak256(abi.encodePacked(sourceAddress)) == keccak256(abi.encodePacked(expectedSourceAddress)),
            "Source address is not trusted"
        );
        
        (bytes memory destinationAddress, bytes[] memory commands) = abi.decode(
            payload, 
            (bytes, bytes[])
        );
        
        address tokenAddress = axelarGateway.tokenAddresses(tokenSymbol);
        require(tokenAddress != address(0), "Token not recognized by gateway");
        
        executeCommands(commands);
        
        emit CommandsReceived(sourceChain, sourceAddress, commands.length);
    }
    
    function emergencyWithdraw(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
    
    function emergencyWithdrawETH(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    function _getCommandData(bytes memory command) private pure returns (bytes memory) {
        require(command.length > 1, "Command too short");
        
        bytes memory data = new bytes(command.length - 1);
        
        for (uint256 i = 0; i < data.length; i++) {
            data[i] = command[i + 1];
        }
        
        return data;
    }

    function _getCommandType(bytes memory command) private pure returns (uint8) {
        require(command.length > 0, "Empty command");
        return uint8(command[0]);
    }
    
    receive() external payable {}
}