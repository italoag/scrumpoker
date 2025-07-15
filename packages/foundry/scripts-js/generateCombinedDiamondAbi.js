import { readFileSync, writeFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

function getArtifactAbi(contractName) {
  const artifactPath = join(__dirname, "..", `out/${contractName}.sol/${contractName}.json`);
  try {
    const artifact = JSON.parse(readFileSync(artifactPath, "utf8"));
    return artifact.abi;
  } catch (error) {
    console.error(`Error reading ${contractName} artifact:`, error.message);
    return [];
  }
}

function combineDiamondAbi() {
  console.log("🔄 Generating combined Diamond ABI...");
  
  // Get ABIs from all facets
  const adminFacetAbi = getArtifactAbi("AdminFacet");
  const nftFacetAbi = getArtifactAbi("NFTFacet");
  const ceremonyFacetAbi = getArtifactAbi("CeremonyFacet");
  const votingFacetAbi = getArtifactAbi("VotingFacet");
  const diamondAbi = getArtifactAbi("ScrumPokerDiamond");
  
  // Combine all ABIs, removing duplicates
  const combinedAbi = [];
  const seenSignatures = new Set();
  
  // Helper function to add unique functions
  function addUniqueAbi(abi, source) {
    abi.forEach(item => {
      let signature;
      if (item.type === "function") {
        signature = `${item.name}(${item.inputs?.map(i => i.type).join(',') || ''})`;
      } else if (item.type === "event") {
        signature = `event_${item.name}(${item.inputs?.map(i => i.type).join(',') || ''})`;
      } else {
        signature = `${item.type}_${JSON.stringify(item)}`;
      }
      
      if (!seenSignatures.has(signature)) {
        seenSignatures.add(signature);
        combinedAbi.push(item);
        console.log(`  ✅ Added ${item.type} ${item.name || item.type} from ${source}`);
      }
    });
  }
  
  // Add ABIs in order: Diamond first (for basic functions), then facets
  addUniqueAbi(diamondAbi, "ScrumPokerDiamond");
  addUniqueAbi(adminFacetAbi, "AdminFacet");
  addUniqueAbi(nftFacetAbi, "NFTFacet");
  addUniqueAbi(ceremonyFacetAbi, "CeremonyFacet");
  addUniqueAbi(votingFacetAbi, "VotingFacet");
  
  console.log(`📊 Combined ABI has ${combinedAbi.length} items`);
  
  // Save combined ABI
  const outputPath = join(__dirname, "..", "out/CombinedDiamond.json");
  writeFileSync(outputPath, JSON.stringify({
    abi: combinedAbi
  }, null, 2));
  
  console.log(`💾 Combined ABI saved to ${outputPath}`);
  
  return combinedAbi;
}

// Generate combined ABI
combineDiamondAbi();