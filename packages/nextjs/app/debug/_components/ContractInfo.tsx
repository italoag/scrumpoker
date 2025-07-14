"use client";

import { Address } from "~~/components/scaffold-eth";

interface ContractInfoProps {
  contractName: string;
  contractAddress: string;
}

export const ContractInfo = ({ contractName, contractAddress }: ContractInfoProps) => {
  return (
    <div className="bg-base-200 rounded-lg p-4 mb-4">
      <h3 className="text-lg font-semibold mb-2">{contractName}</h3>
      <div className="flex items-center gap-2">
        <span className="text-sm font-medium">Address:</span>
        <Address address={contractAddress} />
      </div>

      {contractName === "ScrumPokerDeployer" && (
        <div className="mt-3 p-3 bg-info/10 rounded border-l-4 border-info">
          <h4 className="font-medium text-info mb-1">ℹ️ About Deployer Functions</h4>
          <p className="text-sm text-base-content/70">
            The <code>facetDeployer</code> and <code>diamondDeployer</code> functions return &quot;0x&quot; because they
            are internal deployer contracts that are created dynamically during deployment operations. This is normal
            behavior when no deployment is currently in progress.
          </p>
          <div className="mt-2">
            <p className="text-xs text-base-content/60">
              💡 To see these deployers in action, try calling the <code>deployAll</code> function with an owner
              address.
            </p>
          </div>
        </div>
      )}
    </div>
  );
};
