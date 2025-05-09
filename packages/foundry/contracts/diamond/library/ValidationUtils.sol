// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ValidationUtils
 * @dev Biblioteca com funções utilitárias para validação de entradas e estados
 */
library ValidationUtils {
    /**
     * @dev Verifica se um endereço não é o endereço zero
     * @param addr Endereço a ser verificado
     * @return Verdadeiro se o endereço não for zero
     */
    function isNotZeroAddress(address addr) internal pure returns (bool) {
        return addr != address(0);
    }
    
    /**
     * @dev Reverte se o endereço for o endereço zero
     * @param addr Endereço a ser verificado
     * @param message Mensagem de erro
     */
    function requireNotZeroAddress(address addr, string memory message) internal pure {
        require(addr != address(0), message);
    }
    
    /**
     * @dev Verifica se um valor é maior que zero
     * @param value Valor a ser verificado
     * @return Verdadeiro se o valor for maior que zero
     */
    function isGreaterThanZero(uint256 value) internal pure returns (bool) {
        return value > 0;
    }
    
    /**
     * @dev Reverte se o valor não for maior que zero
     * @param value Valor a ser verificado
     * @param message Mensagem de erro
     */
    function requireGreaterThanZero(uint256 value, string memory message) internal pure {
        require(value > 0, message);
    }
    
    /**
     * @dev Verifica se uma string não está vazia
     * @param str String a ser verificada
     * @return Verdadeiro se a string não estiver vazia
     */
    function isNotEmpty(string memory str) internal pure returns (bool) {
        return bytes(str).length > 0;
    }
    
    /**
     * @dev Reverte se a string estiver vazia
     * @param str String a ser verificada
     * @param message Mensagem de erro
     */
    function requireNotEmpty(string memory str, string memory message) internal pure {
        require(bytes(str).length > 0, message);
    }
}
