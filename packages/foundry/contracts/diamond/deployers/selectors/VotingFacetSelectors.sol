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
        bytes4[] memory selectors = new bytes4[](12);
        selectors[0] = VotingFacet.initializeVoting.selector;
        selectors[1] = VotingFacet.commitVote.selector;
        selectors[2] = VotingFacet.revealVote.selector;
        selectors[3] = VotingFacet.openFunctionalityVote.selector;
        selectors[4] = VotingFacet.commitFunctionalityVote.selector;
        selectors[5] = VotingFacet.revealFunctionalityVote.selector;
        selectors[6] = VotingFacet.closeFunctionalityVote.selector;
        selectors[7] = VotingFacet.updateBadgesRange.selector;
        selectors[8] = VotingFacet.hasVoted.selector;
        selectors[9] = VotingFacet.getVote.selector;
        selectors[10] = VotingFacet.hasFunctionalityVoted.selector;
        selectors[11] = VotingFacet.getFunctionalityVote.selector;
        return selectors;
    }
}