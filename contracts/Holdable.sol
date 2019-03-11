pragma solidity ^0.5;

import "./Compliant.sol";

contract Holdable is Compliant {

    // Data structures (in eternal storage)

    /**
     * @title Holdable - generic holding mechanism for tokenized assets
     *
     * @dev This contract allows wallet owners to put tokens on hold for others. Holds are a sort of "projected payments", where
     * a payer and a payee are specified, along with an amount, a notary and an expiration. When the hold is established, the
     * relevant token balance from the payer (as specified by the amount) is put on hold, i.e. it cannot be transferred or used
     * in any manner until the hold is either executed or released. The hold can only be executed by the notary, which triggers
     * the transfer of the tokens from the payer to the payee. If the hold is not to be executed, it can be released either by
     * the notary at any time or by anyone after the expiration time has been reached
     * (Note: consider allowing the payee to also be able to release the hold, as a way to reject it)
     */
    bytes32 constant private HOLDABLE_CONTRACT_NAME = "Holdable";

    /**
     * @dev Data structures:
     * @dev _HOLDING_APPROVALS : mapping (address => mapping (address => bool)) storing the permissions for addresses
     * to perform holds on behalf of wallets
     */
    bytes32 constant private _HOLDING_APPROVALS = "_holdingApprovals";

    // Events
    // Constructor
    // Modifiers
    // Interface functions
    // Internal functions
    // Private functions

    // External state-modifying functions

    /**
     * @notice This function allows wallet owners to approve other addresses to perform holds on their behalf
     * @dev It is similar to the "approve" method in ERC20, but in this case no allowance is given and this is treated
     * as a "yes or no" flag
     * @param holder The address to be approved as potential issuer of holds
     */
    function approveToHold(address holder) external returns (bool)
    {
        _check(checkApproveToHold, msg.sender, holder);
        return _setHoldingApproval(msg.sender, holder, true);
    }

    /**
     * @notice This function allows wallet owners to revoke holding privileges from previously approved addresses
     * @param holder The address to be revoked as potential issuer of holds
     */
    function revokeApprovalToHold(address holder) external returns (bool)
    {
        return _setHoldingApproval(msg.sender, holder, false);
    }

    /**
     * @notice Function to perform a hold on behalf of a wallet owner (the "payer") in favor of another wallet owner (the
     * "payee"), and specifying a notary who will be 
     * @param holdId An unique ID to identify the hold. Internally IDs will be stored together with the addresses
     * issuing the holds (on a mapping (address => mapping (string => XXX ))), so the same holdId can be used by many
     * different holders. This is provided assuming that the hold functionality is a competitive resource
     * @param payer The address from which the tokens are to be taken (if the hold is executed)
     * @param payee The address to which the tokens are to be paid (if the hold is executed)
     * @param notary The address of the notary who is going to determine whether the hold is to be executed or released
     * @param amount The amount to be transferred
     * @param timeToExpiration The time to be added to the currrent block.timestamp to establish the expiration time for
     * the hold. After the expiration time anyone can actually trigger the release of the hold
     * @return The index in the array where the hold is actually created and stored (this is an unique identifier
     * throughout the whole contract)
     */
    function hold(
        string calldata holdId,
        address payer,
        address payee,
        address notary,
        uint256 amount,
        uint256 timeToExpiration
    )
        external
        returns (uint256 index)
    {
        _check(checkHold, payer, payee);
        require(payer == msg.sender || _getHoldingApproval(msg.sender, payer), "Sender is not approved to hold");
        require(amount >= _availableFunds(payer), "Not enough funds to hold");
        return _createHold(holdId, msg.sender, payer, payee, notary, amount, timeToExpiration);
    }

    /**
     * @notice Function to release a hold (if at all possible)
     * @param issuer The address of the original sender of the hold
     * @param holdId The ID of the hold in question
     * @dev issuer and holdId are needed to index a hold. This is provided so different issuers can use the same holdId,
     * as holding is a competitive resource
     */
    function releaseHold(address issuer, string calldata holdId) external returns (bool) {
        uint256 index;
        address payer;
        address payee;
        address notary;
        uint256 amount;
        uint256 expiration;
        HoldStatusCode status;
        (index, payer, payee, notary, amount, expiration, status) = _holdData(issuer, holdId);
        require(notary != SUSPENSE_WALLET, "This hold cannot be released");
        if(hasRole(msg.sender, OPERATOR_ROLE)) {
            return _finalizeHold(msg.sender, holdId, HoldStatusCode.ReleasedByOperator);
        } else if(notary == msg.sender) {
            return _finalizeHold(msg.sender, holdId, HoldStatusCode.ReleasedByNotary);
        } else if(block.timestamp >= expiration) {
            return _finalizeHold(msg.sender, holdId, HoldStatusCode.ReleasedDueToExpiration);
        } else {
            require(false, "Hold cannot be released");
        }
    }
    
    /**
     * @notice Function to execute a hold (if at all possible)
     * @param issuer The address of the original sender of the hold
     * @param holdId The ID of the hold in question
     * @dev issuer and holdId are needed to index a hold. This is provided so different issuers can use the same holdId,
     * as holding is a competitive resource
     */
    function executeHold(address issuer, string calldata holdId) external returns (bool) {
        uint256 index;
        address payer;
        address payee;
        address notary;
        uint256 amount;
        uint256 expiration;
        HoldStatusCode status;
        (index, payer, payee, notary, amount, expiration, status) = _holdData(issuer, holdId);
        _removeFunds(payer, amount);
        _addFunds(payee, amount);
        if(hasRole(msg.sender, OPERATOR_ROLE)) {
            return _finalizeHold(msg.sender, holdId, HoldStatusCode.ExecutedByOperator);
        } else if(notary == msg.sender) {
            return _finalizeHold(msg.sender, holdId, HoldStatusCode.ExecutedByNotary);
        } else {
            require(false, "Not authorized to execute");
        }
    }
    
    // External view functions

    /**
     * @notice Returns whether an address is approved to submit holds on behalf of other wallets
     * @param wallet The wallet on which the holds would be performed (i.e. the "payer")
     * @param holder The address approved to hold on behalf of the wallet owner
     * @return Whether the holder is approved or not to hold on behalf of the wallet owner
     */
    function isApprovedToHold(address wallet, address holder) external view returns (bool) {
        return _getHoldingApproval(wallet, holder);
    }

    /**
     * @notice Function to retrieve all the information available for a particular hold
     * @param issuer The address of the original sender of the hold
     * @param holdId The ID of the hold in question
     * @return index: the index of the hold (an unique identifier)
     * @return payer: the wallet from which the tokens will be taken if the hold is executed
     * @return payee: the wallet to which the tokens will be transferred if the hold is executed
     * @return notary: the address that will be executing or releasing the hold
     * @return amount: the amount that will be transferred
     * @return expiration: the absolute time (block.timestamp) by which the hold will expire (after that time
     * the hold can be released by anyone)
     * @return status: the current status of the hold
     * @dev issuer and holdId are needed to index a hold. This is provided so different issuers can use the same holdId,
     * as holding is a competitive resource
     */
    function retrieveHoldData(address issuer, string calldata holdId)
        external view
        returns (
            uint256 index,
            address payer,
            address payee,
            address notary,
            uint256 amount,
            uint256 expiration,
            HoldStatusCode status
        )
    {
        return _holdData(issuer, holdId);
    }

    /**
     * @dev Function to know how much is locked on hold from a particular wallet
     * @param account The address of the account
     * @return The balance on hold for a particular account
     */
    function balanceOnHold(address account) external view returns (uint256) {
        return _balanceOnHold(account);
    }

    /**
     * @dev Function to know how much is locked on hold for all accounts
     * @return The total amount in balances on hold from all wallets
     */
    function totalSupplyOnHold() external view returns (uint256) {
        return _totalSupplyOnHold();
    }

    // Private functions

    function _getHoldingApproval(address wallet, address holder) private view returns (bool) {
        return getBoolFromDoubleMapping(HOLDABLE_CONTRACT_NAME, _HOLDING_APPROVALS, wallet, holder);
    }

    function _setHoldingApproval(address wallet, address holder, bool value) private returns (bool) {
        return setBoolInDoubleMapping(HOLDABLE_CONTRACT_NAME, _HOLDING_APPROVALS, wallet, holder, value);
    }

}

