"use client";

import { useAccount } from "wagmi";
import { useScaffoldWriteContract, useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";

export const useScrumPokerContracts = () => {
  const { address } = useAccount();

  // All contract operations now use ScrumPokerDiamond
  const { writeContractAsync: writeContract } = useScaffoldWriteContract({
    contractName: "ScrumPokerDiamond",
  });

  // AdminFacet read operations
  const { data: isPaused } = useScaffoldReadContract({
    contractName: "ScrumPokerDiamond",
    functionName: "isPaused",
  });

  const { data: exchangeRate } = useScaffoldReadContract({
    contractName: "ScrumPokerDiamond",
    functionName: "getExchangeRate",
  });

  console.log("🔍 Exchange rate from contract:", exchangeRate);

  const { data: vestingPeriod } = useScaffoldReadContract({
    contractName: "ScrumPokerDiamond",
    functionName: "getVestingPeriod",
  });

  // NFTFacet read operations
  const { data: userToken } = useScaffoldReadContract({
    contractName: "ScrumPokerDiamond",
    functionName: "getUserToken",
    args: [address || "0x0000000000000000000000000000000000000000"],
  });

  const { data: isVested } = useScaffoldReadContract({
    contractName: "ScrumPokerDiamond",
    functionName: "isVested",
    args: [address || "0x0000000000000000000000000000000000000000"],
  });

  const { data: nftBalance } = useScaffoldReadContract({
    contractName: "ScrumPokerDiamond",
    functionName: "balanceOf",
    args: [address || "0x0000000000000000000000000000000000000000"],
  });

  // CeremonyFacet read operations
  const getCeremony = (ceremonyCode: string) => {
    return useScaffoldReadContract({
      contractName: "ScrumPokerDiamond",
      functionName: "getCeremony",
      args: [ceremonyCode],
    });
  };

  const checkCeremonyExists = (ceremonyCode: string) => {
    return useScaffoldReadContract({
      contractName: "ScrumPokerDiamond",
      functionName: "ceremonyExists",
      args: [ceremonyCode],
    });
  };

  const checkIsApproved = (ceremonyCode: string, participant: string) => {
    return useScaffoldReadContract({
      contractName: "ScrumPokerDiamond",
      functionName: "isApproved",
      args: [ceremonyCode, participant],
    });
  };

  // VotingFacet read operations
  const getCeremonyResults = (ceremonyCode: string) => {
    return useScaffoldReadContract({
      contractName: "ScrumPokerDiamond",
      functionName: "getCeremonyResults",
      args: [ceremonyCode],
    });
  };

  const getFunctionalityResults = (ceremonyCode: string, sessionIndex: number) => {
    return useScaffoldReadContract({
      contractName: "ScrumPokerDiamond",
      functionName: "getFunctionalityResults",
      args: [ceremonyCode, BigInt(sessionIndex)],
    });
  };

  const hasVoted = (ceremonyCode: string, participant: string) => {
    return useScaffoldReadContract({
      contractName: "ScrumPokerDiamond",
      functionName: "hasVoted",
      args: [ceremonyCode, participant],
    });
  };

  // Contract operations
  const startCeremony = async (sprintNumber: number) => {
    console.log("startCeremony called with sprintNumber:", sprintNumber);
    console.log("address:", address);
    console.log("writeContract:", writeContract);
    
    try {
      if (!address) {
        console.log("No address, showing error notification");
        notification.error("Please connect your wallet");
        return;
      }

      console.log("About to call writeContract");
      const result = await writeContract({
        functionName: "startCeremony",
        args: [BigInt(sprintNumber)],
      });

      console.log("writeContract result:", result);
      notification.success("Ceremony started successfully!");
      return result;
    } catch (error) {
      console.error("Error starting ceremony:", error);
      notification.error("Failed to start ceremony");
      throw error;
    }
  };

  const concludeCeremony = async (ceremonyCode: string) => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "concludeCeremony",
        args: [ceremonyCode],
      });

      notification.success("Ceremony concluded successfully!");
      return result;
    } catch (error) {
      console.error("Error concluding ceremony:", error);
      notification.error("Failed to conclude ceremony");
      throw error;
    }
  };

  const requestCeremonyEntry = async (ceremonyCode: string) => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "requestCeremonyEntry",
        args: [ceremonyCode],
      });

      notification.success("Entry request sent successfully!");
      return result;
    } catch (error) {
      console.error("Error requesting ceremony entry:", error);
      notification.error("Failed to request ceremony entry");
      throw error;
    }
  };

  const approveEntry = async (ceremonyCode: string, participant: string) => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "approveEntry",
        args: [ceremonyCode, participant],
      });

      notification.success("Entry approved successfully!");
      return result;
    } catch (error) {
      console.error("Error approving entry:", error);
      notification.error("Failed to approve entry");
      throw error;
    }
  };

  const openFunctionalityVote = async (ceremonyCode: string, functionalityCode: string) => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "openFunctionalityVote",
        args: [ceremonyCode, functionalityCode],
      });

      notification.success("Voting session opened successfully!");
      return result;
    } catch (error) {
      console.error("Error opening voting session:", error);
      notification.error("Failed to open voting session");
      throw error;
    }
  };

  const commitVote = async (ceremonyCode: string, commit: string) => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "commitVote",
        args: [ceremonyCode, commit as `0x${string}`],
      });

      notification.success("Vote committed successfully!");
      return result;
    } catch (error) {
      console.error("Error committing vote:", error);
      notification.error("Failed to commit vote");
      throw error;
    }
  };

  const revealVote = async (ceremonyCode: string, voteValue: number, salt: string) => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "revealVote",
        args: [ceremonyCode, BigInt(voteValue), salt as `0x${string}`],
      });

      notification.success("Vote revealed successfully!");
      return result;
    } catch (error) {
      console.error("Error revealing vote:", error);
      notification.error("Failed to reveal vote");
      throw error;
    }
  };

  const commitFunctionalityVote = async (ceremonyCode: string, sessionIndex: number, commit: string) => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "commitFunctionalityVote",
        args: [ceremonyCode, BigInt(sessionIndex), commit as `0x${string}`],
      });

      notification.success("Functionality vote committed successfully!");
      return result;
    } catch (error) {
      console.error("Error committing functionality vote:", error);
      notification.error("Failed to commit functionality vote");
      throw error;
    }
  };

  const revealFunctionalityVote = async (ceremonyCode: string, sessionIndex: number, voteValue: number, salt: string) => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "revealFunctionalityVote",
        args: [ceremonyCode, BigInt(sessionIndex), BigInt(voteValue), salt as `0x${string}`],
      });

      notification.success("Functionality vote revealed successfully!");
      return result;
    } catch (error) {
      console.error("Error revealing functionality vote:", error);
      notification.error("Failed to reveal functionality vote");
      throw error;
    }
  };

  const purchaseNFT = async (userName: string, externalURI: string) => {
    console.log("=== purchaseNFT called ===");
    console.log("userName:", userName);
    console.log("externalURI:", externalURI);
    console.log("address:", address);
    console.log("exchangeRate:", exchangeRate);
    console.log("writeContract function:", writeContract);
    
    try {
      if (!address) {
        console.log("❌ No wallet address");
        notification.error("Please connect your wallet");
        return;
      }

      if (!exchangeRate) {
        console.log("❌ No exchange rate available");
        notification.error("Exchange rate not available");
        return;
      }

      console.log("✅ All checks passed, calling writeContract...");
      console.log("Function name: purchaseNFT");
      console.log("Args:", [userName, externalURI]);
      console.log("Value (wei):", exchangeRate);

      const result = await writeContract({
        functionName: "purchaseNFT",
        args: [userName, externalURI],
        value: exchangeRate,
      });

      console.log("✅ NFT purchase transaction result:", result);
      notification.success("NFT purchased successfully!");
      return result;
    } catch (error) {
      console.error("❌ Error purchasing NFT:", error);
      console.error("Error details:", JSON.stringify(error, null, 2));
      notification.error("Failed to purchase NFT");
      throw error;
    }
  };

  const refundNFT = async () => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "refundNFT",
      });

      notification.success("NFT refunded successfully!");
      return result;
    } catch (error) {
      console.error("Error refunding NFT:", error);
      notification.error("Failed to refund NFT");
      throw error;
    }
  };

  // Admin functions
  const pauseContract = async () => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "pause",
      });

      notification.success("Contract paused successfully!");
      return result;
    } catch (error) {
      console.error("Error pausing contract:", error);
      notification.error("Failed to pause contract");
      throw error;
    }
  };

  const unpauseContract = async () => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "unpause",
      });

      notification.success("Contract unpaused successfully!");
      return result;
    } catch (error) {
      console.error("Error unpausing contract:", error);
      notification.error("Failed to unpause contract");
      throw error;
    }
  };

  const updateExchangeRate = async (newRate: string) => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "updateExchangeRate",
        args: [BigInt(newRate)],
      });

      notification.success("Exchange rate updated successfully!");
      return result;
    } catch (error) {
      console.error("Error updating exchange rate:", error);
      notification.error("Failed to update exchange rate");
      throw error;
    }
  };

  const grantRole = async (role: string, account: string) => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "grantRole",
        args: [role as `0x${string}`, account as `0x${string}`],
      });

      notification.success("Role granted successfully!");
      return result;
    } catch (error) {
      console.error("Error granting role:", error);
      notification.error("Failed to grant role");
      throw error;
    }
  };

  const revokeRole = async (role: string, account: string) => {
    try {
      if (!address) {
        notification.error("Please connect your wallet");
        return;
      }

      const result = await writeContract({
        functionName: "revokeRole",
        args: [role as `0x${string}`, account as `0x${string}`],
      });

      notification.success("Role revoked successfully!");
      return result;
    } catch (error) {
      console.error("Error revoking role:", error);
      notification.error("Failed to revoke role");
      throw error;
    }
  };

  return {
    // Contract operations
    startCeremony,
    concludeCeremony,
    requestCeremonyEntry,
    approveEntry,
    openFunctionalityVote,
    commitVote,
    revealVote,
    commitFunctionalityVote,
    revealFunctionalityVote,
    purchaseNFT,
    refundNFT,
    
    // Admin operations
    pauseContract,
    unpauseContract,
    updateExchangeRate,
    grantRole,
    revokeRole,
    
    // Read data
    isPaused,
    exchangeRate,
    vestingPeriod,
    userToken,
    isVested,
    nftBalance,
    
    // Read functions
    getCeremony,
    checkCeremonyExists,
    checkIsApproved,
    getCeremonyResults,
    getFunctionalityResults,
    hasVoted,
    
    // User info
    address,
    isConnected: !!address,
  };
};