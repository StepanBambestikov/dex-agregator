// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {IAxelarGasService} from "../../src/OuterChainRouter.sol";

contract MockAxelarGasService is IAxelarGasService {
    event PayGasForContractCallWithToken(
        address sender,
        string destinationChain,
        string destinationAddress,
        bytes payload,
        string symbol,
        uint256 amount,
        address refundAddress
    );
    
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable override {
        emit PayGasForContractCallWithToken(
            sender,
            destinationChain,
            destinationAddress,
            payload,
            symbol,
            amount,
            refundAddress
        );
    }
}