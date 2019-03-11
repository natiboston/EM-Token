pragma solidity ^0.5;

import "./ConsolidatedLedger.sol";
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
contract Compliant is ConsolidatedLedger, Whitelistable {

    // Data structures (in eternal storage)
        
    // Events
    // Constructor
    // Modifiers
    // Interface functions

    // ERC20
    
    function checkTransfer(address from, address to) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(from)) {
            reason = "Sender is not whitelisted";
        } else if(!_isWhitelisted(to)) {
            reason = "Receiver is not whitelisted";
        } else {
            canDo = true;
        }
    }

    function checkApprove(address allower, address spender) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(allower)) {
            reason = "Allower is not whitelisted";
        } else if(!_isWhitelisted(spender)) {
            reason = "Spender is not whitelisted";
        } else {
            canDo = true;
        }
    }

    // Holdable

    function checkHold(address payer, address payee) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(payer)) {
            reason = "Payer is not whitelisted";
        } else if(!_isWhitelisted(payee)) {
            reason = "Payee is not whitelisted";
        } else {
            canDo = true;
        }
    }

    function checkApproveToHold(address payer, address holder) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(payer)) {
            reason = "Payer is not whitelisted";
        } else if(!_isWhitelisted(holder)) {
            reason = "Holder is not whitelisted";
        } else {
            canDo = true;
        }
    }

    // Clearable
    
    function checkApproveToRequestClearedTransfer(address walletToDebit, address requester) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(walletToDebit)) {
            reason = "Wallet to debit not whitelisted";
        } else if(!_isWhitelisted(requester)) {
            reason = "Requester not whitelisted";
        } else {
            canDo = true;
        }
    }

    function checkRequestClearedTransfer(address walletToDebit, address requester) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(walletToDebit)) {
            reason = "Wallet to debit not whitelisted";
        } else if(!_isWhitelisted(requester)) {
            reason = "Requester not whitelisted";
        } else {
            canDo = true;
        }
    }

    // Fundable
    
    function checkApproveToRequestFunding(address walletToFund, address requester) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(walletToFund)) {
            reason = "Wallet to fund not whitelisted";
        } else if(!_isWhitelisted(requester)) {
            reason = "Requester not whitelisted";
        } else {
            canDo = true;
        }
    }

    function checkRequestFunding(address walletToFund, address requester) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(walletToFund)) {
            reason = "Wallet to fund not whitelisted";
        } else if(!_isWhitelisted(requester)) {
            reason = "Requester not whitelisted";
        } else {
            canDo = true;
        }
    }

    // Payoutable
    
    function checkApproveToRequestPayout(address walletToDebit, address requester) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(walletToDebit)) {
            reason = "Wallet to debit not whitelisted";
        } else if(!_isWhitelisted(requester)) {
            reason = "Requester not whitelisted";
        } else {
            canDo = true;
        }
    }

    function checkRequestPayout(address walletToDebit, address requester) public view
        returns (bool canDo, string memory reason)
    {
        if(!_isWhitelisted(walletToDebit)) {
            reason = "Wallet to debit not whitelisted";
        } else if(!_isWhitelisted(requester)) {
            reason = "Requester not whitelisted";
        } else {
            canDo = true;
        }
    }

    // Internal functions

    function _check(bool test) internal pure {
        require(test, "Check failed");
    }

    function _check(function(address, address) returns (bool, string memory) checkFunction, address a, address b) internal {
        bool test;
        string memory reason;
        (test, reason) = checkFunction(a, b);
        require(test, reason);
    }

    function _check(function(address) returns (bool, string memory) checkFunction, address a) internal {
        bool test;
        string memory reason;
        (test, reason) = checkFunction(a);
        require(test, reason);
    }

    // Private functions

}
