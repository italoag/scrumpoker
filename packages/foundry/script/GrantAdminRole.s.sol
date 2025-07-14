// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/facets/AdminFacet.sol";

contract GrantAdminRole is Script {
    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerPrivateKey);

        // Endereço do AdminFacet deployado
        address adminFacetAddress = 0xe95C81b36A0f77a4940368931D2612bDF6D4ed20;
        AdminFacet adminFacet = AdminFacet(adminFacetAddress);

        // Endereço da wallet que precisa de permissão ADMIN
        address walletToGrant = 0x27e1Beb25112BEb6631Ac1FA5F83286DA6a508A1;

        // Role ADMIN_ROLE
        bytes32 adminRole = keccak256("ADMIN_ROLE");

        // Conceder permissão de ADMIN
        adminFacet.grantRole(adminRole, walletToGrant);

        console.log("ADMIN role granted to:", walletToGrant);

        vm.stopBroadcast();
    }
}