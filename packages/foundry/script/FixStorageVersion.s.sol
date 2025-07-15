// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/ScrumPokerStorage.sol";

contract FixStorageVersion is Script {
    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerPrivateKey);
        
        address diamond = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;
        
        // Primeiro, vamos verificar a versão atual
        console.log("Checking current storage version...");
        
        // Ler diretamente do storage slot
        bytes32 slot = keccak256("ScrumPokerStorage.DiamondStorage");
        bytes32 versionSlot = bytes32(uint256(slot) + 0); // version é o primeiro campo
        uint256 currentVersion = uint256(vm.load(diamond, versionSlot));
        
        console.log("Current version:", currentVersion);
        console.log("Expected version:", ScrumPokerStorage.CURRENT_STORAGE_VERSION);
        
        if (currentVersion == 0) {
            console.log("Storage version is 0, need to initialize it");
            
            // Vamos tentar definir a versão diretamente
            bytes32 newVersionValue = bytes32(ScrumPokerStorage.CURRENT_STORAGE_VERSION);
            vm.store(diamond, versionSlot, newVersionValue);
            
            // Verificar se foi definido
            uint256 newVersion = uint256(vm.load(diamond, versionSlot));
            console.log("New version after setting:", newVersion);
        }
        
        vm.stopBroadcast();
    }
}