// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";
import "../contracts/diamond/ScrumPokerStorage.sol";

contract SetupAdmin is Script {
    function run() external {
        // Use a chave privada do Anvil account 1 (que fez o deployment)
        uint256 deployerPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Using deployer address:", deployerAddress);
        
        vm.startBroadcast(deployerPrivateKey);

        // Endereço do AdminFacet deployado
        address adminFacetAddress = 0xc6B8FBF96CF7bbE45576417EC2163AcecFA88ECC;
        AdminFacet adminFacet = AdminFacet(adminFacetAddress);

        try adminFacet.grantRole(ScrumPokerStorage.ADMIN_ROLE, deployerAddress) {
            console.log("ADMIN_ROLE granted to deployer");
        } catch {
            console.log("Failed to grant ADMIN_ROLE - trying to bootstrap via call");
            
            // Tenta chamar diretamente o storage para dar bootstrap
            // Isso é um hack temporário para configurar o primeiro admin
            bytes memory data = abi.encodeWithSignature("bootstrapAdmin(address)", deployerAddress);
            (bool success, ) = adminFacetAddress.call(data);
            if (success) {
                console.log("Bootstrap admin successful");
            } else {
                console.log("Bootstrap admin failed");
            }
        }

        // Agora tenta definir o exchange rate
        try adminFacet.updateExchangeRate(1000000) {
            console.log("Exchange rate updated to 1000000 WEI");
        } catch {
            console.log("Failed to update exchange rate");
        }

        vm.stopBroadcast();
    }
}