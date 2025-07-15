"use client";

// Quick test to check if contract data is loading
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";

export default function TestContractData() {
  const { data: exchangeRate, error: exchangeRateError, isLoading: exchangeRateLoading } = useScaffoldReadContract({
    contractName: "ScrumPokerDiamond",
    functionName: "getExchangeRate",
  });

  const { data: vestingPeriod, error: vestingPeriodError, isLoading: vestingPeriodLoading } = useScaffoldReadContract({
    contractName: "ScrumPokerDiamond", 
    functionName: "getVestingPeriod",
  });

  console.log("=== CONTRACT DATA TEST ===");
  console.log("Exchange Rate:", { data: exchangeRate, error: exchangeRateError, isLoading: exchangeRateLoading });
  console.log("Vesting Period:", { data: vestingPeriod, error: vestingPeriodError, isLoading: vestingPeriodLoading });

  return (
    <div className="container mx-auto p-8">
      <h1 className="text-2xl font-bold mb-4">Contract Data Test</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body">
            <h2 className="card-title">Exchange Rate</h2>
            <p>
              {exchangeRateLoading ? "Loading..." : 
               exchangeRateError ? `Error: ${exchangeRateError.message}` :
               exchangeRate ? `${(Number(exchangeRate) / 1e18).toFixed(6)} ETH` : "No data"}
            </p>
          </div>
        </div>
        
        <div className="card bg-base-100 shadow-xl">
          <div className="card-body">
            <h2 className="card-title">Vesting Period</h2>
            <p>
              {vestingPeriodLoading ? "Loading..." : 
               vestingPeriodError ? `Error: ${vestingPeriodError.message}` :
               vestingPeriod ? `${Number(vestingPeriod) / 86400} days` : "No data"}
            </p>
          </div>
        </div>
      </div>
      
      {(exchangeRateError || vestingPeriodError) && (
        <div className="alert alert-error mt-4">
          <span>Contract errors detected. Check console for details.</span>
        </div>
      )}
    </div>
  );
}