// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";

contract FindErrorSelectors is Script {
    function run() external pure {
        console.log("=== Finding Error Selectors ===");
        
        // NFT Errors
        console.log("NFTAlreadyPurchased():", vm.toString(bytes4(keccak256("NFTAlreadyPurchased()"))));
        console.log("IncorrectPaymentAmount():", vm.toString(bytes4(keccak256("IncorrectPaymentAmount()"))));
        console.log("WithdrawalFailed():", vm.toString(bytes4(keccak256("WithdrawalFailed()"))));
        console.log("NotPaused():", vm.toString(bytes4(keccak256("NotPaused()"))));
        console.log("NoNFT():", vm.toString(bytes4(keccak256("NoNFT()"))));
        console.log("NotAuthorized():", vm.toString(bytes4(keccak256("NotAuthorized()"))));
        
        // Ceremony Errors
        console.log("CeremonyNotFound():", vm.toString(bytes4(keccak256("CeremonyNotFound()"))));
        console.log("CeremonyNotActive():", vm.toString(bytes4(keccak256("CeremonyNotActive()"))));
        console.log("EntryAlreadyRequested():", vm.toString(bytes4(keccak256("EntryAlreadyRequested()"))));
        console.log("EntryNotRequested():", vm.toString(bytes4(keccak256("EntryNotRequested()"))));
        console.log("ParticipantAlreadyApproved():", vm.toString(bytes4(keccak256("ParticipantAlreadyApproved()"))));
        console.log("NFTRequired():", vm.toString(bytes4(keccak256("NFTRequired()"))));
        
        // Admin Errors
        console.log("ZeroAddress():", vm.toString(bytes4(keccak256("ZeroAddress()"))));
        console.log("InvalidVestingPeriod():", vm.toString(bytes4(keccak256("InvalidVestingPeriod()"))));
        console.log("TransferFailed():", vm.toString(bytes4(keccak256("TransferFailed()"))));
        console.log("OracleFailure():", vm.toString(bytes4(keccak256("OracleFailure()"))));
        console.log("InvalidOracleData():", vm.toString(bytes4(keccak256("InvalidOracleData()"))));
        
        // Check if any unknown error matches known patterns
        console.log("=== Checking for 0x23519ef2 ===");
        if (bytes4(keccak256("NFTAlreadyPurchased()")) == 0x23519ef2) {
            console.log("MATCH: NFTAlreadyPurchased()");
        }
        
        console.log("=== Checking for 0xdcec23bb ===");
        // Let's try some other possible errors
        console.log("AlreadyVoted():", vm.toString(bytes4(keccak256("AlreadyVoted()"))));
        console.log("NFTNotVested():", vm.toString(bytes4(keccak256("NFTNotVested()"))));
        console.log("SessionNotFound():", vm.toString(bytes4(keccak256("SessionNotFound()"))));
        console.log("SessionNotActive():", vm.toString(bytes4(keccak256("SessionNotActive()"))));
        console.log("DuplicateFunctionalitySession():", vm.toString(bytes4(keccak256("DuplicateFunctionalitySession()"))));
        console.log("InvalidRange():", vm.toString(bytes4(keccak256("InvalidRange()"))));
        console.log("InvalidVoteValue():", vm.toString(bytes4(keccak256("InvalidVoteValue()"))));
        console.log("InvalidCommit():", vm.toString(bytes4(keccak256("InvalidCommit()"))));
        console.log("AlreadyCommitted():", vm.toString(bytes4(keccak256("AlreadyCommitted()"))));
        console.log("NoCommitFound():", vm.toString(bytes4(keccak256("NoCommitFound()"))));
        console.log("RevealPhaseNotActive():", vm.toString(bytes4(keccak256("RevealPhaseNotActive()"))));
        console.log("InvalidReveal():", vm.toString(bytes4(keccak256("InvalidReveal()"))));
        
        // Check for specific match
        if (bytes4(keccak256("NFTRequired()")) == 0xdcec23bb) {
            console.log("MATCH for 0xdcec23bb: NFTRequired()");
        }
        if (bytes4(keccak256("ParticipantNotApproved()")) == 0xdcec23bb) {
            console.log("MATCH for 0xdcec23bb: ParticipantNotApproved()");
        }
        
        console.log("ParticipantNotApproved():", vm.toString(bytes4(keccak256("ParticipantNotApproved()"))));
        
        console.log("=== End ===");
    }
}