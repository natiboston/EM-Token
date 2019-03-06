pragma solidity ^0.5;

import "./IEMoneyToken.sol";
import "./ERC20.sol";
import "./Holdable.sol";
import "./Overdraftable.sol";
import "./Clearable.sol";
import "./Fundable.sol";
import "./Payoutable.sol";

    // Data structures (in eternal storage)
    // Events
    // Constructor
    // Modifiers
    // Interface functions
    // Internal functions
    // Private functions

contract EMoneyToken is IEMoneyToken, ERC20, Holdable, Overdraftable, Clearable, Fundable, Payoutable {

    // Data structures (in eternal storage)

    bytes32 constant private EMONEYTOKEN_CONTRACT_NAME = "EMoneyToken";

    /**
     * @dev Data structures (implemented in the eternal storage):
     * @dev _NAME : string with the name of the token (e.g. "Santander Electronic Money Token")
     * @dev _SYMBOL : string with the symbol / ticker of the token (e.g. "SANEMEUR")
     * @dev _CURRENCY : string with the symbol of the currency (e.g. "EUR")
     * @dev _DECIMALS : uint with the number of decimals (e.g. 2 for cents) (this is for information purposes only)
     */
    bytes32 constant private _NAME = "_name";
    bytes32 constant private _SYMBOL = "_symbol";
    bytes32 constant private _CURRENCY = "_currency";
    bytes32 constant private _DECIMALS = "_decimals";

    string constant private _version = "0.1.0";

    // Events

    event created(string name, string symbol, string currency, uint8 decimals, string version);

    // Constructor

    constructor (string memory name, string memory symbol, string memory currency, uint8 decimals) public {
        setString(EMONEYTOKEN_CONTRACT_NAME, _NAME, name);
        setString(EMONEYTOKEN_CONTRACT_NAME, _SYMBOL, symbol);
        setString(EMONEYTOKEN_CONTRACT_NAME, _CURRENCY, currency);
        setUint(EMONEYTOKEN_CONTRACT_NAME, _DECIMALS, uint256(decimals));
        emit created(name, symbol, currency, decimals, _version);
    }

    // Interface functions

    /**
     * @notice Show the name of the tokenizer entity
     * @return the name of the token.
     */
    function name() external view returns (string memory) {
        return getString(EMONEYTOKEN_CONTRACT_NAME, _NAME);
    }

    /**
     * @notice Show the symbol of the token
     * @return the symbol of the token.
     */
    function symbol() external view returns (string memory) {
        return getString(EMONEYTOKEN_CONTRACT_NAME, _SYMBOL);
    }

    /**
     * @notice Show the currency that backs the token
     * @return the currency of the token.
     */
    function currency() external view returns (string memory) {
        return getString(EMONEYTOKEN_CONTRACT_NAME, _CURRENCY);
    }

    /**
     * @notice Show the number of decimals of the token (remember, this is just for information purposes)
     * @return the number of decimals of the token.
     */
    function decimals() external view returns (uint8) {
        return uint8(getUint(EMONEYTOKEN_CONTRACT_NAME, _DECIMALS));
    }

    /**
     * @notice Show the current version
     * @return the version of the smart contract.
     */
    function version() external pure returns (string memory) {
        return _version;
    }

    // Internal functions

    // Private functions

}