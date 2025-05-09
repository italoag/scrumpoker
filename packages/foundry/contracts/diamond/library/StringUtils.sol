// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title StringUtils
 * @dev Biblioteca com funções utilitárias para manipulação de strings
 */
library StringUtils {
    /**
     * @dev Converte uma string para bytes32 usando keccak256
     * @param str String para converter
     * @return Hash da string em formato bytes32
     */
    function stringToBytes32(string memory str) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }
    
    /**
     * @dev Verifica se duas strings são iguais
     * @param a Primeira string
     * @param b Segunda string
     * @return Verdadeiro se as strings forem iguais
     */
    function equals(string memory a, string memory b) internal pure returns (bool) {
        return stringToBytes32(a) == stringToBytes32(b);
    }
    
    /**
     * @dev Verifica se uma string está vazia
     * @param str String para verificar
     * @return Verdadeiro se a string estiver vazia
     */
    function isEmpty(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }
    
    /**
     * @dev Concatena duas strings
     * @param a Primeira string
     * @param b Segunda string
     * @return Strings concatenadas
     */
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    
    /**
     * @dev Concatena duas strings com um separador
     * @param a Primeira string
     * @param separator Separador
     * @param b Segunda string
     * @return Strings concatenadas com separador
     */
    function concatWithSeparator(string memory a, string memory separator, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, separator, b));
    }
}
