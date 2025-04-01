// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {IAxelarGateway} from "../../src/OuterChainRouter.sol";

contract MockAxelarGateway is IAxelarGateway {
    event ContractCallWithToken(
        string destinationChain, 
        string contractAddress, 
        bytes payload, 
        string symbol, 
        uint256 amount
    );
    
    mapping(string => address) private _tokenAddresses;
    
    function setTokenAddress(string memory symbol, address tokenAddress) public {
        _tokenAddresses[symbol] = tokenAddress;
    }
    
    function tokenAddresses(string calldata symbol) external view override returns (address) {
        return _tokenAddresses[symbol];
    }
    
    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external override {
        emit ContractCallWithToken(destinationChain, contractAddress, payload, symbol, amount);
    }
}