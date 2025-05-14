// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./DeployHelper.s.sol";
import "../contracts/YourContract.sol";

/**
 * @notice Deploy script for YourContract contract
 * @dev Inherits DeployHelper which:
 *      - Includes forge-std/Script.sol for deployment
 *      - Includes DeployerRunner modifier
 *      - Provides `deployer` variable
 * Example:
 * yarn deploy --file DeployYourContract.s.sol  # local anvil chain
 * yarn deploy --file DeployYourContract.s.sol --network optimism # live network (requires keystore)
 */
contract DeployYourContract is DeployHelper {
    /**
     * @dev Deployer setup based on `ETH_KEYSTORE_ACCOUNT` in `.env`:
     *      - "scaffold-eth-default": Uses Anvil's account #9 (0xa0Ee7A142d267C1f36714E4a8F75612F20a79720), no password prompt
     *      - "scaffold-eth-custom": requires password used while creating keystore
     *
     * Note: Must use DeployerRunner modifier to:
     *      - Setup correct `deployer` account and fund it
     *      - Export contract addresses & ABIs to `nextjs` packages
     */
    function run() external DeployerRunner {
        new YourContract(deployer);
    }
}
