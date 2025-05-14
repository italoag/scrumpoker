//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { Vm } from "forge-std/Vm.sol";

contract DeployHelper is Script {
    error InvalidChain();
    error DeployerHasNoBalance();
    error InvalidPrivateKey(string);

    event AnvilSetBalance(address account, uint256 amount);
    event FailedAnvilRequest();

    struct Deployment {
        string name;
        address addr;
    }

    string root;
    string path;
    Deployment[] public deployments;
    uint256 constant ANVIL_BASE_BALANCE = 10000 ether;

    /// @notice The deployer address for every run
    address deployer;

    /// @notice Use this modifier on your run() function on your deploy scripts
    modifier DeployerRunner() {
        deployer = _startBroadcast();
        if (deployer == address(0)) {
            revert InvalidPrivateKey("Invalid private key");
        }
        _;
        _stopBroadcast();
        exportDeployments();
    }

    function _startBroadcast() internal returns (address) {
        vm.startBroadcast();
        (, address _deployer,) = vm.readCallers();

        if (block.chainid == 31337 && _deployer.balance == 0) {
            try this.anvil_setBalance(_deployer, ANVIL_BASE_BALANCE) {
                emit AnvilSetBalance(_deployer, ANVIL_BASE_BALANCE);
            } catch {
                emit FailedAnvilRequest();
            }
        } 
        return _deployer;
    }

    function _stopBroadcast() internal {
        vm.stopBroadcast();
    }

    function exportDeployments() internal {
        // fetch already existing contracts
        root = vm.projectRoot();
        path = string.concat(root, "/deployments/");
        string memory chainIdStr = vm.toString(block.chainid);
        path = string.concat(path, string.concat(chainIdStr, ".json"));

        string memory jsonWrite;

        uint256 len = deployments.length;

        for (uint256 i = 0; i < len; i++) {
            vm.serializeString(jsonWrite, vm.toString(deployments[i].addr), deployments[i].name);
        }

        string memory chainName;

        try this.getChain() returns (Chain memory chain) {
            chainName = chain.name;
        } catch {
            chainName = findChainName();
        }
        jsonWrite = vm.serializeString(jsonWrite, "networkName", chainName);
        vm.writeJson(jsonWrite, path);
    }

    function getChain() public returns (Chain memory) {
        return getChain(block.chainid);
    }

    function anvil_setBalance(address addr, uint256 amount) public {
        string memory addressString = vm.toString(addr);
        string memory amountString = vm.toString(amount);
        string memory requestPayload = string.concat(
            '{"method":"anvil_setBalance","params":["', addressString, '","', amountString, '"],"id":1,"jsonrpc":"2.0"}'
        );

        string[] memory inputs = new string[](8);
        inputs[0] = "curl";
        inputs[1] = "-X";
        inputs[2] = "POST";
        inputs[3] = "http://localhost:8545";
        inputs[4] = "-H";
        inputs[5] = "Content-Type: application/json";
        inputs[6] = "--data";
        inputs[7] = requestPayload;

        vm.ffi(inputs);
    }

    function findChainName() public returns (string memory) {
        uint256 thisChainId = block.chainid;
        bool isBesuDetected = false;
        string memory besuConsensusType = "";
        
        // First check if this is a Besu network by checking client version
        try this.isBesuNetwork() returns (bool isBesu, string memory consensusType) {
            if (isBesu) {
                // Return chain name based on Besu + chainId + consensusType
                isBesuDetected = true;
                besuConsensusType = consensusType;
                return string.concat("Besu-", vm.toString(thisChainId), "-", consensusType);
            }
        } catch {
            // If Besu check fails, continue with normal RPC checks
        }

        // Fallback to the original method of finding chain name
        string[2][] memory allRpcUrls = vm.rpcUrls();
        for (uint256 i = 0; i < allRpcUrls.length; i++) {
            try vm.createSelectFork(allRpcUrls[i][1]) {
                if (block.chainid == thisChainId) {
                    return allRpcUrls[i][0];
                }
            } catch {
                continue;
            }
        }
        
        // If Besu was detected but we didn't return early (for some reason),
        // use the Besu name
        if (isBesuDetected) {
            return string.concat("Besu-", vm.toString(thisChainId), "-", besuConsensusType);
        }
        
        // If we reach here, we couldn't identify the chain - revert with InvalidChain
        revert InvalidChain();
    }

    /// @notice Checks if the connected network is Hyperledger Besu and identifies its consensus algorithm
    /// @return isBesu Boolean indicating if this is a Besu network
    /// @return consensusType The consensus protocol being used (CLIQUE, QBFT, IBFT, RAFT, or "Unknown")
    function isBesuNetwork() public returns (bool isBesu, string memory consensusType) {
        // Make a JSON-RPC call to get client info
        string memory clientInfo = makeJsonRpcCall("web3_clientVersion", "");
        
        // Check if it's Besu by looking for "besu" in the client version
        if (containsString(clientInfo, "besu")) {
            isBesu = true;
            
            // Try to determine consensus algorithm using eth_getBlockByNumber
            // This can help identify the consensus mechanism by checking block header
            string memory blockInfo = makeJsonRpcCall("eth_getBlockByNumber", "[\"latest\", false]");
            
            if (containsString(blockInfo, "clique")) {
                consensusType = "CLIQUE";
            } else if (containsString(blockInfo, "qbft")) {
                consensusType = "QBFT";
            } else if (containsString(blockInfo, "ibft")) {
                consensusType = "IBFT";
            } else if (containsString(blockInfo, "raft")) {
                consensusType = "RAFT";
            } else {
                // Try a more specific Besu-only method to check mining algorithm
                string memory besuInfo = makeJsonRpcCall("besu_consensusMechanism", "");
                
                if (bytes(besuInfo).length > 0) {
                    // Parse the response for QBFT, IBFT, etc.
                    if (containsString(besuInfo, "QBFT")) {
                        consensusType = "QBFT";
                    } else if (containsString(besuInfo, "IBFT")) {
                        consensusType = "IBFT";
                    } else if (containsString(besuInfo, "CLIQUE")) {
                        consensusType = "CLIQUE";
                    } else if (containsString(besuInfo, "RAFT")) {
                        consensusType = "RAFT";
                    } else {
                        consensusType = "Unknown";
                    }
                } else {
                    consensusType = "Unknown";
                }
            }
            
            return (true, consensusType);
        }
        
        return (false, "");
    }
    
    /// @notice Makes a JSON-RPC call to the current RPC endpoint
    /// @param method The JSON-RPC method to call
    /// @param params The parameters for the method (as a JSON string)
    /// @return response The response from the JSON-RPC call
    function makeJsonRpcCall(string memory method, string memory params) internal returns (string memory) {
        // We need to get the RPC URL currently being used
        // First, let's get the chain ID to help us identify the network
        uint256 chainId = block.chainid;
        
        // Use the current chain's URL rather than localhost
        string memory currentRpcUrl;
        
        // Try to get RPC URLs from vm.rpcUrls()
        string[2][] memory allRpcUrls = vm.rpcUrls();
        for (uint256 i = 0; i < allRpcUrls.length; i++) {
            try vm.createSelectFork(allRpcUrls[i][1]) {
                if (block.chainid == chainId) {
                    currentRpcUrl = allRpcUrls[i][1];
                    break;
                }
            } catch {
                continue;
            }
        }
        
        // If we couldn't find a matching RPC URL, use a custom one without a port
        if (bytes(currentRpcUrl).length == 0) {
            currentRpcUrl = "https://rpc-besu.cluster.eita.cloud";
        }
        
        string memory requestPayload = string.concat(
            '{"method":"', method, '","params":', 
            bytes(params).length == 0 ? "[]" : params,
            ',"id":1,"jsonrpc":"2.0"}'
        );

        string[] memory inputs = new string[](8);
        inputs[0] = "curl";
        inputs[1] = "-X";
        inputs[2] = "POST";
        inputs[3] = currentRpcUrl; // Use the actual RPC URL from above
        inputs[4] = "-H";
        inputs[5] = "Content-Type: application/json";
        inputs[6] = "--data";
        inputs[7] = requestPayload;

        // In Solidity, we need to catch specific operations
        bytes memory result;
        try vm.ffi(inputs) returns (bytes memory res) {
            result = res;
        } catch {
            result = "";
        }
        return string(result);
    }
    
    /// @notice Checks if a string contains a substring
    /// @param source The source string to search in
    /// @param searchFor The substring to find
    /// @return True if the substring is found, false otherwise
    function containsString(string memory source, string memory searchFor) internal pure returns (bool) {
        bytes memory sourceBytes = bytes(source);
        bytes memory searchBytes = bytes(searchFor);
        
        if (searchBytes.length > sourceBytes.length) {
            return false;
        }
        
        for (uint i = 0; i <= sourceBytes.length - searchBytes.length; i++) {
            bool found = true;
            
            for (uint j = 0; j < searchBytes.length; j++) {
                if (sourceBytes[i + j] != searchBytes[j]) {
                    found = false;
                    break;
                }
            }
            
            if (found) {
                return true;
            }
        }
        
        return false;
    }
}
