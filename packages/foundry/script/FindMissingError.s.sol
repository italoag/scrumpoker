// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";

contract FindMissingError is Script {
    function run() external pure {
        console.log("=== Finding Missing Error 0xdcec23bb ===");
        
        // Check different patterns that might produce this selector
        string[50] memory possibleErrors = [
            "Paused()",
            "NotInitialized()",
            "AlreadyInitialized()",
            "InvalidAmount()",
            "InvalidParameter()",
            "InvalidCall()",
            "InvalidState()",
            "ContractPaused()",
            "NotScrumMaster()",
            "NotOwner()",
            "NotAdmin()",
            "InsufficientBalance()",
            "InvalidInput()",
            "InvalidUser()",
            "InvalidToken()",
            "Unauthorized()",
            "AccessDenied()",
            "FunctionNotFound()",
            "InvalidContract()",
            "ContractNotFound()",
            "InvalidAddress()",
            "AddressZero()",
            "EmptyString()",
            "InvalidString()",
            "InvalidLength()",
            "OutOfBounds()",
            "ArrayEmpty()",
            "InvalidIndex()",
            "DivisionByZero()",
            "Overflow()",
            "Underflow()",
            "TransactionFailed()",
            "CallFailed()",
            "ReentrancyGuard()",
            "TimelockNotExpired()",
            "DeadlineExpired()",
            "InvalidSignature()",
            "InvalidNonce()",
            "InvalidPeriod()",
            "InvalidRole()",
            "RoleNotFound()",
            "PermissionDenied()",
            "ActionNotAllowed()",
            "OperationFailed()",
            "ExecutionFailed()",
            "ValidationFailed()",
            "InitializationFailed()",
            "ConfigurationError()",
            "SystemError()",
            "UnknownError()"
        ];
        
        bytes4 target = 0xdcec23bb;
        
        for (uint i = 0; i < possibleErrors.length; i++) {
            bytes4 selector = bytes4(keccak256(bytes(possibleErrors[i])));
            if (selector == target) {
                console.log("FOUND MATCH:", possibleErrors[i]);
                console.log("Selector:", vm.toString(selector));
                break;
            }
        }
        
        // Also check manually for some specific cases
        console.log("Target:", vm.toString(target));
        console.log("Trying some variations...");
        
        // These are common in OpenZeppelin contracts
        console.log("Pausable__Paused():", vm.toString(bytes4(keccak256("Pausable__Paused()"))));
        console.log("Ownable__NotOwner():", vm.toString(bytes4(keccak256("Ownable__NotOwner()"))));
        console.log("AccessControl__NotAdmin():", vm.toString(bytes4(keccak256("AccessControl__NotAdmin()"))));
        
        // Check some more specific ones
        console.log("=== More specific checks ===");
        console.log("ContractPaused():", vm.toString(bytes4(keccak256("ContractPaused()"))));
        console.log("NotScrumMaster():", vm.toString(bytes4(keccak256("NotScrumMaster()"))));
        console.log("InvalidCaller():", vm.toString(bytes4(keccak256("InvalidCaller()"))));
        console.log("NoPermission():", vm.toString(bytes4(keccak256("NoPermission()"))));
        
        // Let's try one more batch
        console.log("=== More variations ===");
        console.log("NotOwner():", vm.toString(bytes4(keccak256("NotOwner()"))));
        console.log("NotAdmin():", vm.toString(bytes4(keccak256("NotAdmin()"))));
        console.log("AccessDenied():", vm.toString(bytes4(keccak256("AccessDenied()"))));
        console.log("Unauthorized():", vm.toString(bytes4(keccak256("Unauthorized()"))));
        console.log("ForbiddenAction():", vm.toString(bytes4(keccak256("ForbiddenAction()"))));
        console.log("NotAllowed():", vm.toString(bytes4(keccak256("NotAllowed()"))));
        
        console.log("=== Check if it's one of the known ones ===");
        if (bytes4(keccak256("NFTRequired()")) == target) {
            console.log("MATCH: NFTRequired()");
        }
        if (bytes4(keccak256("NotAuthorized()")) == target) {
            console.log("MATCH: NotAuthorized()");
        }
        
        console.log("=== End ===");
    }
}