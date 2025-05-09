// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title DeployerUtils
 * @dev Biblioteca com funções utilitárias para o processo de implantação
 */
library DeployerUtils {
    /**
     * @dev Verifica se um endereço é um contrato
     * @param _addr Endereço a ser verificado
     * @return true se o endereço contém código de contrato
     */
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
    
    /**
     * @dev Gera um hash do bytecode
     * @param _code Bytecode para gerar o hash
     * @return Hash do bytecode
     */
    function getCodeHash(bytes memory _code) internal pure returns (bytes32) {
        return keccak256(_code);
    }
    
    /**
     * @dev Converte bytes4[] para bytes
     * @param _selectors Array de seletores (bytes4)
     * @return Bytes concatenados
     */
    function convertSelectorsToBytes(bytes4[] memory _selectors) internal pure returns (bytes memory) {
        bytes memory result = new bytes(_selectors.length * 4);
        for (uint i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            assembly {
                mstore(add(add(result, 0x20), mul(i, 4)), selector)
            }
        }
        return result;
    }
    
    /**
     * @dev Compara duas strings
     * @param a Primeira string
     * @param b Segunda string
     * @return true se as strings são iguais
     */
    function stringEquals(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
