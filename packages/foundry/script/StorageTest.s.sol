// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/diamond/ScrumPokerStorage.sol";

/**
 * @notice Test to check diamond storage directly
 */
contract StorageTest is Script {
    function run() external view {
        // Get the diamond address from deployments
        string memory deploymentFile = string.concat(vm.projectRoot(), "/deployments/anvil.json");
        string memory json = vm.readFile(deploymentFile);
        address payable diamondAddress = payable(vm.parseJsonAddress(json, ".ScrumPokerDiamond"));
        
        console.log("=== Storage Test ===");
        console.log("Diamond address:", diamondAddress);
        
        // Calculate the storage position for diamond storage
        bytes32 storagePosition = keccak256("diamond.storage.scrumpoker");
        console.log("Storage position:", vm.toString(storagePosition));
        
        // Read storage directly from the diamond address
        bytes32 versionSlot = vm.load(diamondAddress, storagePosition);
        console.log("Version slot value:", vm.toString(versionSlot));
        
        // Read exchange rate (should be at storagePosition + 1)
        bytes32 exchangeRateSlot = bytes32(uint256(storagePosition) + 1);
        bytes32 exchangeRateValue = vm.load(diamondAddress, exchangeRateSlot);
        console.log("Exchange rate slot value:", vm.toString(exchangeRateValue));
        console.log("Exchange rate as uint256:", uint256(exchangeRateValue));
        
        // Read vesting period (should be at storagePosition + 2)
        bytes32 vestingPeriodSlot = bytes32(uint256(storagePosition) + 2);
        bytes32 vestingPeriodValue = vm.load(diamondAddress, vestingPeriodSlot);
        console.log("Vesting period slot value:", vm.toString(vestingPeriodValue));
        console.log("Vesting period as uint256:", uint256(vestingPeriodValue));
        
        // Check roles mapping for deployer
        address deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        bytes32 adminRole = ScrumPokerStorage.ADMIN_ROLE;
        bytes32 priceUpdaterRole = ScrumPokerStorage.PRICE_UPDATER_ROLE;
        
        console.log("");
        console.log("Deployer address:", deployer);
        console.log("ADMIN_ROLE:", vm.toString(adminRole));
        console.log("PRICE_UPDATER_ROLE:", vm.toString(priceUpdaterRole));
        
        // Calculate role mapping slots
        // roles[role][account] mapping is at offset 12 in the struct
        bytes32 rolesBaseSlot = bytes32(uint256(storagePosition) + 12);
        
        // For mapping(bytes32 => mapping(address => bool)), the slot is:
        // keccak256(abi.encode(account, keccak256(abi.encode(role, rolesBaseSlot))))
        bytes32 adminRoleSlot = keccak256(abi.encode(adminRole, rolesBaseSlot));
        bytes32 adminRoleForDeployerSlot = keccak256(abi.encode(deployer, adminRoleSlot));
        bytes32 adminRoleValue = vm.load(diamondAddress, adminRoleForDeployerSlot);
        console.log("Deployer ADMIN_ROLE value:", vm.toString(adminRoleValue));
        console.log("Deployer has ADMIN_ROLE:", uint256(adminRoleValue) != 0);
        
        bytes32 priceUpdaterRoleSlot = keccak256(abi.encode(priceUpdaterRole, rolesBaseSlot));
        bytes32 priceUpdaterRoleForDeployerSlot = keccak256(abi.encode(deployer, priceUpdaterRoleSlot));
        bytes32 priceUpdaterRoleValue = vm.load(diamondAddress, priceUpdaterRoleForDeployerSlot);
        console.log("Deployer PRICE_UPDATER_ROLE value:", vm.toString(priceUpdaterRoleValue));
        console.log("Deployer has PRICE_UPDATER_ROLE:", uint256(priceUpdaterRoleValue) != 0);
        
        console.log("=== Storage Test Complete ===");
    }
}