// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {IDEXAdapter} from "src/adapters/adapter.sol";


//The contract is used to store all the states needed for routing within a single blockchain.
// The functionality provides CRUD operations on adapters, as well as the ability to enable/disable them.
contract InnerChainRegistry is Ownable, ReentrancyGuard {
    using EnumerableMap for EnumerableMap.Bytes32ToBytes32Map;

    struct AdapterInfo {
        address adapterAddress;
        bool isActive;
    }

    mapping(bytes32 => AdapterInfo) private _adapters;
    EnumerableMap.Bytes32ToBytes32Map private _dexKeys;

    event AdapterAdded(string indexed dexName, address adapter);
    event AdapterUpdated(string indexed dexName, address oldAdapter, address newAdapter);
    event AdapterRemoved(string indexed dexName);
    event AdapterStatusChanged(string indexed dexName, bool isActive);

    constructor() Ownable(msg.sender) {}

    function addAdapter(string memory dexName, address adapterAddress) external onlyOwner {
        require(bytes(dexName).length > 0, "DEX name cannot be empty");
        require(adapterAddress != address(0), "Adapter address cannot be zero");
        
        bytes32 dexKey = keccak256(bytes(dexName));
        require(!_dexKeys.contains(dexKey), "DEX with this name already exists");
        
        string memory adapterName = IDEXAdapter(adapterAddress).getName();
        require(bytes(adapterName).length > 0, "Invalid adapter interface");
        
        _adapters[dexKey] = AdapterInfo({
            adapterAddress: adapterAddress,
            isActive: true
        });
        
        _dexKeys.set(dexKey, bytes32(bytes(dexName)));
        
        emit AdapterAdded(dexName, adapterAddress);
    }

    function updateAdapter(string memory dexName, address newAdapterAddress) external onlyOwner {
        require(bytes(dexName).length > 0, "DEX name cannot be empty");
        require(newAdapterAddress != address(0), "New adapter address cannot be zero");
        
        bytes32 dexKey = keccak256(bytes(dexName));
        require(_dexKeys.contains(dexKey), "DEX not registered");
        
        address oldAdapter = _adapters[dexKey].adapterAddress;
        require(oldAdapter != newAdapterAddress, "New address is the same as current");
        
        string memory adapterName = IDEXAdapter(newAdapterAddress).getName();
        require(bytes(adapterName).length > 0, "Invalid adapter interface");
        
        _adapters[dexKey].adapterAddress = newAdapterAddress;
        
        emit AdapterUpdated(dexName, oldAdapter, newAdapterAddress);
    }

    function setAdapterStatus(string memory dexName, bool isActive) external onlyOwner {
        bytes32 dexKey = keccak256(bytes(dexName));
        require(_dexKeys.contains(dexKey), "DEX not registered");
        require(_adapters[dexKey].isActive != isActive, "Status already set");
        
        _adapters[dexKey].isActive = isActive;
        
        emit AdapterStatusChanged(dexName, isActive);
    }

    function removeAdapter(string memory dexName) external onlyOwner {
        bytes32 dexKey = keccak256(bytes(dexName));
        require(_dexKeys.contains(dexKey), "DEX not registered");

        delete _adapters[dexKey];
        _dexKeys.remove(dexKey);
        
        emit AdapterRemoved(dexName);
    }

    function getAllDexNames() external view returns (string[] memory) {
        uint256 length = _dexKeys.length();
        string[] memory names = new string[](length);
        
        for (uint256 i = 0; i < length; i++) {
            (, bytes32 nameBytes) = _dexKeys.at(i);
            names[i] = _bytesToString(nameBytes);
        }
        
        return names;
    }

    function getActiveDexNames() external view returns (string[] memory) {
        uint256 totalLength = _dexKeys.length();
        
        uint256 activeCount = 0;
        for (uint256 i = 0; i < totalLength; i++) {
            (bytes32 key, ) = _dexKeys.at(i);
            if (_adapters[key].isActive) {
                activeCount++;
            }
        }
        
        string[] memory activeNames = new string[](activeCount);
        
        uint256 activeIndex = 0;
        for (uint256 i = 0; i < totalLength; i++) {
            (bytes32 key, bytes32 nameBytes) = _dexKeys.at(i);
            if (_adapters[key].isActive) {
                activeNames[activeIndex] = _bytesToString(nameBytes);
                activeIndex++;
            }
        }
        
        return activeNames;
}

    function getAdapterInfo(string memory dexName) external view returns (address, bool) {
        bytes32 dexKey = keccak256(bytes(dexName));
        require(_dexKeys.contains(dexKey), "DEX not registered");
        
        AdapterInfo memory adapter = _adapters[dexKey];
        return (adapter.adapterAddress, adapter.isActive);
    }
    
    function isDexRegistered(string memory dexName) external view returns (bool) {
        bytes32 dexKey = keccak256(bytes(dexName));
        return _dexKeys.contains(dexKey);
    }
    
    function _bytesToString(bytes32 bytesData) internal pure returns (string memory) {
        uint8 i = 0;
        for (; i < 32; i++) {
            if (bytesData[i] == 0) {
                break;
            }
        }
        
        bytes memory bytesArray = new bytes(i);
        for (uint8 j = 0; j < i; j++) {
            bytesArray[j] = bytesData[j];
        }
        
        return string(bytesArray);
    }
}