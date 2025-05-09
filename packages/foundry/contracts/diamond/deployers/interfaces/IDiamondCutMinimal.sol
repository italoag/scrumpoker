// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@solidity-lib/diamond/Diamond.sol";

/**
 * @title IDiamondCutMinimal
 * @dev Interface minimalista para acessar o método diamondCut do padrão Diamond
 */
interface IDiamondCutMinimal {
    function diamondCut(
        Diamond.Facet[] memory facets,
        address init,
        bytes memory calldata_
    ) external;
}
