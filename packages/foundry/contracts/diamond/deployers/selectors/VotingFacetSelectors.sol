// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../../facets/VotingFacet.sol";

/**
 * @title VotingFacetSelectors
 * @dev Biblioteca para obter os seletores da VotingFacet
 */
library VotingFacetSelectors {
    /**
     * @dev Retorna todos os seletores da VotingFacet
     * @return Array de seletores como bytes4[]
     */
    function getSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](10);
        selectors[0] = VotingFacet.initializeVoting.selector;
        selectors[1] = VotingFacet.vote.selector;
        selectors[2] = VotingFacet.openFunctionalityVote.selector;
        selectors[3] = VotingFacet.voteFunctionality.selector;
        selectors[4] = VotingFacet.closeFunctionalityVote.selector;
        selectors[5] = VotingFacet.updateBadges.selector;
        selectors[6] = VotingFacet.hasVoted.selector;
        selectors[7] = VotingFacet.getVote.selector;
        selectors[8] = VotingFacet.hasFunctionalityVoted.selector;
        selectors[9] = VotingFacet.getFunctionalityVote.selector;
        return selectors;
    }
}
