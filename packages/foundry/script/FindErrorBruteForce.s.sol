// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";

contract FindErrorBruteForce is Script {
    function run() external pure {
        bytes4 target = 0xdcec23bb;
        console.log("Looking for error with selector:", vm.toString(target));
        
        // Check all possible errors from the contracts
        string[110] memory errors = [
            "EnforcedPause()",
            "ExpectedPause()",
            "ReentrancyGuardReentrantCall()",
            "NotInitializing()",
            "AlreadyInitialized()",
            "NotInitialized()",
            "InvalidInitialization()",
            "ERC721InvalidOwner(address)",
            "ERC721NonexistentToken(uint256)",
            "ERC721IncorrectOwner(address,uint256,address)",
            "ERC721InvalidSender(address)",
            "ERC721InvalidReceiver(address)",
            "ERC721InsufficientApproval(address,uint256)",
            "ERC721InvalidApprover(address)",
            "ERC721InvalidOperator(address)",
            "NFTAlreadyPurchased()",
            "IncorrectPaymentAmount()",
            "WithdrawalFailed()",
            "NotPaused()",
            "NoNFT()",
            "NotAuthorized()",
            "CeremonyNotFound()",
            "CeremonyNotActive()",
            "EntryAlreadyRequested()",
            "EntryNotRequested()",
            "ParticipantAlreadyApproved()",
            "NFTRequired()",
            "ZeroAddress()",
            "InvalidVestingPeriod()",
            "TransferFailed()",
            "OracleFailure()",
            "InvalidOracleData()",
            "ParticipantNotApproved()",
            "AlreadyVoted()",
            "NFTNotVested()",
            "SessionNotFound()",
            "SessionNotActive()",
            "DuplicateFunctionalitySession()",
            "InvalidRange()",
            "InvalidVoteValue()",
            "InvalidCommit()",
            "AlreadyCommitted()",
            "NoCommitFound()",
            "RevealPhaseNotActive()",
            "InvalidReveal()",
            "InsufficientFunds(uint256,uint256)",
            "OnlyOwner()",
            "OnlyAdmin()",
            "OnlyAuthorized()",
            "Paused()",
            "NotPaused()",
            "InvalidAmount()",
            "InvalidAddress()",
            "InvalidParameter()",
            "InvalidState()",
            "InvalidOperation()",
            "CallFailed()",
            "TransactionFailed()",
            "ExecutionFailed()",
            "ValidationFailed()",
            "InitializationFailed()",
            "ConfigurationError()",
            "SystemError()",
            "UnknownError()",
            "AccessControlUnauthorizedAccount(address,bytes32)",
            "AccessControlBadConfirmation()",
            "SafeERC20FailedOperation(address)",
            "SafeERC20FailedDecreaseAllowance(address,uint256,uint256)",
            "AddressEmptyCode(address)",
            "AddressInsufficientBalance(address)",
            "FailedInnerCall()",
            "InvalidShortString()",
            "StringTooLong(string)",
            "ECDSAInvalidSignature()",
            "ECDSAInvalidSignatureLength(uint256)",
            "ECDSAInvalidSignatureS(bytes32)",
            "MathOverflowedMulDiv()",
            "OwnableUnauthorizedAccount(address)",
            "OwnableInvalidOwner(address)",
            "PausableEnforcedPause()",
            "PausableExpectedPause()",
            "ReentrancyGuardReentrantCall()",
            "SafeCastOverflowedUintDowncast(uint8,uint256)",
            "SafeCastOverflowedIntToUint(int256)",
            "SafeCastOverflowedUintToInt(uint256)",
            "SafeCastOverflowedIntDowncast(uint8,int256)",
            "UUPSUnauthorizedCallContext()",
            "UUPSUnsupportedProxiableUUID(bytes32)",
            "ERC1967InvalidImplementation(address)",
            "ERC1967NonPayable()",
            "FailedCall()",
            "InsufficientBalance(uint256,uint256)",
            "InvalidRecipient()",
            "InvalidSender()",
            "InvalidData()",
            "InvalidCall()",
            "InvalidValue()",
            "InvalidToken()",
            "InvalidUser()",
            "InvalidCaller()",
            "InvalidInput()",
            "InvalidOutput()",
            "InvalidLength()",
            "InvalidIndex()",
            "InvalidNonce()",
            "InvalidSignature()",
            "InvalidTime()",
            "InvalidPeriod()",
            "InvalidRole()",
            "InvalidPermission()"
        ];
        
        for (uint i = 0; i < errors.length; i++) {
            bytes4 selector = bytes4(keccak256(bytes(errors[i])));
            if (selector == target) {
                console.log("FOUND MATCH:", errors[i]);
                console.log("Selector:", vm.toString(selector));
                return;
            }
        }
        
        console.log("No match found in the list above");
        
        // Let's try a different approach - check what the actual selector is
        console.log("Let me try calculating manually...");
        
        bytes4 testSelector = bytes4(keccak256("EnforcedPause()"));
        console.log("EnforcedPause() selector:", vm.toString(testSelector));
        
        if (testSelector == target) {
            console.log("MATCH FOUND: EnforcedPause()");
        }
        
        // Check pause related errors
        console.log("=== Checking Pause-related errors ===");
        console.log("EnforcedPause():", vm.toString(bytes4(keccak256("EnforcedPause()"))));
        console.log("ExpectedPause():", vm.toString(bytes4(keccak256("ExpectedPause()"))));
        console.log("PausableEnforcedPause():", vm.toString(bytes4(keccak256("PausableEnforcedPause()"))));
        console.log("PausableExpectedPause():", vm.toString(bytes4(keccak256("PausableExpectedPause()"))));
        
        // Check for common OpenZeppelin errors
        console.log("=== Checking OpenZeppelin errors ===");
        console.log("ReentrancyGuardReentrantCall():", vm.toString(bytes4(keccak256("ReentrancyGuardReentrantCall()"))));
        console.log("OwnableUnauthorizedAccount(address):", vm.toString(bytes4(keccak256("OwnableUnauthorizedAccount(address)"))));
        console.log("AccessControlUnauthorizedAccount(address,bytes32):", vm.toString(bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)"))));
        
        console.log("=== End ===");
    }
}