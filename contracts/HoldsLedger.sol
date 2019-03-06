pragma solidity ^0.5;

import "./EternalStorageWrapper.sol";
import "./libraries/SafeMath.sol";

contract HoldsLedger is EternalStorageWrapper {

    using SafeMath for uint256;

    // Data structures (in eternal storage)

    bytes32 constant private HOLDSLEDGER_CONTRACT_NAME = "HoldsLedger";

    /**
     * @dev Data structures (implemented in the eternal storage):
     * @dev _HOLD_IDS : bytes32 array with hold IDs
     */

    // Events

    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Constructor

    // Modifiers

    // Interface functions

    // Internal functions

    // Private functions
    
}
