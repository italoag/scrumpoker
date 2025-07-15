// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";

contract TestEvents is Script {
    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerPrivateKey);

        // Endereço do CeremonyFacet deployado
        address ceremonyFacetAddress = 0x4A679253410272dd5232B3Ff7cF5dbB88f295319;

        // Tentando chamar uma função simples para testar
        (bool success, bytes memory data) = ceremonyFacetAddress.call(
            abi.encodeWithSignature("startCeremony(uint256)", 1)
        );

        if (success) {
            console.log("Ceremony started successfully");
        } else {
            console.log("Failed to start ceremony");
            console.logBytes(data);
        }

        vm.stopBroadcast();
    }
}