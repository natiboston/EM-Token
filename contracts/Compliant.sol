pragma solidity ^0.5;

import "./ERC20Ledger.sol";
import "./HoldsLedger.sol";
import "./OverdraftsLedger.sol";
import "./RoleControl.sol";

/**
 * @title Compliant
 * @dev This contract implements check methods that can be called upstream or from outside. By doing a "require"
 * on this methods one can check whether user-initiated methods (e.g. transfer) can actually be executed due to
 * compliance restrictions (e.g. only whitelisted users should be able to send or receive in transfer methods)
 * @dev Intermediate data is used in this contract as well (implemented over the EternalStorage construct) in
 * order to implement permissioning logic (e.g. whitelisting flags, or cumulative cashins or cashouts to check
 * cumulative limits)
 */
contract Compliant is ERC20Ledger, HoldsLedger, OverdraftsLedger, RoleControl {

    // Data structures (in eternal storage)
    // Events
    // Constructor
    // Modifiers
    // Interface functions
    // Internal functions
    // Private functions

}
