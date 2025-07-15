// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";

contract GrantAdminRole is Script {
    function run() external {
        // Recupera a chave privada do ambiente ou usa uma padrão para testes
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        
        // Endereço do deployer derivado da chave privada
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Using deployer address:", deployerAddress);
        
        vm.startBroadcast(deployerPrivateKey);

        // Endereço do AdminFacet deployado (deployment atualizado)
        address adminFacetAddress = 0xf7Cd8fa9b94DB2Aa972023b379c7f72c65E4De9D;
        AdminFacet adminFacet = AdminFacet(adminFacetAddress);

        // Endereço da wallet que precisa de permissão ADMIN
        address walletToGrant = 0x6695EBF9b8057742faaAb700023a8ba7Cb1470a0;

        // Role ADMIN_ROLE
        bytes32 adminRole = keccak256("ADMIN_ROLE");

        // Conceder permissão de ADMIN
        adminFacet.grantRole(adminRole, walletToGrant);

        console.log("ADMIN role granted to:", walletToGrant);

        vm.stopBroadcast();
    }
}
