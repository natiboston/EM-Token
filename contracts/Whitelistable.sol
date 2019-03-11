pragma solidity ^0.5;

import "./RoleControl.sol";


/**
 * @title Whitelistable
 * @dev The Whitelistable contract implements a simple whitelisting mechanism that can be used upstream to
 * ensure that only whitelisted wallets are allowed to transact
 */
contract Whitelistable is RoleControl {

    address constant SUSPENSE_WALLET = address(0);

// Data structures (in eternal storage)

    bytes32 constant private WHITELISTABLE_CONTRACT_NAME = "Whitelistable";

    /**
     * @dev Data structures
     * @dev _WHITELIST_ARRAY : address array with the addresses of the whitelisted wallets
     * @dev _WHITELIST_MAPPING : mapping (address => uint) with the indices of the whitelisted wallets
     */
    bytes32 constant private _WHITELIST_ARRAY = "_whitelistArray";
    bytes32 constant private _WHITELIST_MAPPING = "_whitelistMapping";

// Event

    event Whitelisted(address who);
    event UnWhitelisted(address who);

// Constructor

    constructor() internal {
        _pushAddressToWhitelist(SUSPENSE_WALLET);
    }

// Modifiers

    modifier onlyWhitelisted(address who) {
        require(_isWhitelisted(who), "Address not whitelisted");
        _;
    }

// External state-modifying functions

    /**
     * @dev Whitelist an individual address
     * @param who The address to be whitelisted
     */
    function whitelist(address who) external onlyRole(OPERATOR_ROLE) returns (uint256) {
        emit Whitelisted(who);
        return _pushAddressToWhitelist(who);
    }

    /**
     * @dev Unwhitelist an individual address
     * @param who The address to be unwhitelisted
     */
    function unWhitelist(address who) external onlyRole(OPERATOR_ROLE) returns (bool) {
        emit UnWhitelisted(who);
        return _deleteAddressFromWhitelist(who);
    }

// External view functions

    /**
     * @dev Number of whitelisted wallets
     */
    function manyWhitelistedWallets() external view returns (uint256) {
        return _getNumberOfWhitelistedWallets();
    }

    /**
     * @dev Array position of a wallet for an address
     * @dev (0 is for address(0), otherwise the wallet is not declared)
     * @param who address The address to obtain the corresponding wallet
     */
    function indexInWhitelist(address who) external view returns (uint256 index) {
        index = _getWhitelistedIndex(who);
        require(index > 0, "Address is not whitelisted");
    }

    /**
     * @dev Returns the address for a wallet in the array
     * @param index The position in the array
     */
    function whichWhitelistedAddress(uint256 index) external view returns (address) {
        return _getWhitelistedAddress(index);
    } 

    /**
     * @dev Returns whether an address is whitelisted
     * @param who The address in question
     */
    function isWhitelisted(address who) external view returns (bool) {
        return _isWhitelisted(who);
    }

    // Internal functions

    function _isWhitelisted(address who) internal view returns (bool) {
        return _getWhitelistedIndex(who) > 0;
    }

    // Private functions

    function _pushAddressToWhitelist(address who) private returns (uint256 index) {
        require(!_isWhitelisted(who), "Address is already whitelisted");
        pushAddressToArray(WHITELISTABLE_CONTRACT_NAME, _WHITELIST_ARRAY, who);
        index = _getNumberOfWhitelistedWallets();
        setUintInMapping(WHITELISTABLE_CONTRACT_NAME, _WHITELIST_MAPPING, who, index);
    }

    function _deleteAddressFromWhitelist(address who) private returns (bool) {
        uint256 index = _getWhitelistedIndex(who);
        require(index > 0, "Address is not whitelisted");
        return
            deleteAddressFromArray(WHITELISTABLE_CONTRACT_NAME, _WHITELIST_ARRAY, index) &&
            deleteAddressFromMapping(WHITELISTABLE_CONTRACT_NAME, _WHITELIST_MAPPING, who);
    }

    function _getWhitelistedAddress(uint256 index) private view returns (address) {
        return getAddressFromArray(WHITELISTABLE_CONTRACT_NAME, _WHITELIST_ARRAY, index);
    }

    function _getWhitelistedIndex(address who) private view returns (uint256 index) {
        index = getUintFromMapping(WHITELISTABLE_CONTRACT_NAME, _WHITELIST_MAPPING, who);
    }

    function _getNumberOfWhitelistedWallets() private view returns (uint256) {
        return getNumberOfElementsInArray(WHITELISTABLE_CONTRACT_NAME, _WHITELIST_ARRAY);
    }

}