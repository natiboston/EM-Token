pragma solidity ^0.5;

import "./ERC20Ledger.sol";
import "./HoldsLedger.sol";
import "./OverdraftsLedger.sol";
import "./Whitelistable.sol";

/**
 * @title Compliant
 * @dev This contract implements check methods that can be called upstream or from outside. By doing a "require"
 * on this methods one can check whether user-initiated methods (e.g. transfer) can actually be executed due to
 * compliance restrictions (e.g. only whitelisted users should be able to send or receive in transfer methods)
 * @dev Intermediate data is used in this contract as well (implemented over the EternalStorage construct) in
 * order to implement permissioning logic (e.g. whitelisting flags, or cumulative cashins or cashouts to check
 * cumulative limits)
 */
contract Compliant is ERC20Ledger, HoldsLedger, OverdraftsLedger, Whitelistable {

    // Data structures (in eternal storage)
    
    uint public constant MAX_AMOUNT = 2**256 - 1;
    
    // Events
    // Constructor
    // Modifiers
    // Interface functions

    // ERC20
    
    function checkTransfer(address from, address to, uint256 value) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(from)) {
            reason = "Sender is not whitelisted";
        } else if(!_isWhitelisted(to)) {
            reason = "Receiver is not whitelisted";
        } else if(value > MAX_AMOUNT) {
            reason = "Value too big";
        } else {
            canDo = true;
        }
    }

    function checkApprove(address allower, address spender, uint256 value) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(allower)) {
            reason = "Allower is not whitelisted";
        } else if(!_isWhitelisted(spender)) {
            reason = "Spender is not whitelisted";
        } else if(value > MAX_AMOUNT) {
            reason = "Amount too big";
        } else {
            canDo = true;
        }
    }

    // Fundable
    
    function checkApproveToRequestFunding(address walletToFund, address requester, uint256 amount) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(walletToFund)) {
            reason = "Wallet to fund not whitelisted";
        } else if(!_isWhitelisted(requester)) {
            reason = "Requester not whitelisted";
        } else if(amount > MAX_AMOUNT) {
            reason = "Amount too big";
        } else{
            canDo = true;
        }
    }

    function checkRequestFunding(address requester, uint256 amount) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(requester)) {
            reason = "Requester not whitelisted";
        } else if(amount > MAX_AMOUNT) {
            reason = "Amount too big";
        } else {
            canDo = true;
        }
    }

    // Internal functions

    function _check(bool test) internal pure {
        require(test, "Check failed");
    }

    function _check(function(address, address, uint256) returns (bool, string memory) checkFunction, address a, address b, uint256 c) internal {
        bool test;
        string memory reason;
        (test, reason) = checkFunction(a, b, c);
        require(test, reason);
    }

    function _check(function(address, uint256) returns (bool, string memory) checkFunction, address a, uint256 b) internal {
        bool test;
        string memory reason;
        (test, reason) = checkFunction(a, b);
        require(test, reason);
    }

    // Private functions

}
