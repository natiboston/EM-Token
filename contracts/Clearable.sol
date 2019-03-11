pragma solidity ^0.5;

import "./libraries/SafeMath.sol";
import "./Compliant.sol";

REVIEW ALL THIS!!!!!


/**
 * @title Clearable
 * @notice Clearable provides ERC20-like token contracts with a workflow to request and honor cleared transfer requests to
 * external bank accounts. Cleared transfer requests are issued by wallet owners (or delegated to other requesters with a
 * "requestFrom" type of method), and requests are executed or rejected by the tokenizing entity (i.e. processed by
 * the owner of the overall contract)
 */
contract Clearable is Compliant {

    using SafeMath for uint256;

    enum ClearedTransferRequestStatusCode { Nonexistent, Requested, InProcess, Executed, Rejected, Cancelled }

    // Data structures (in eternal storage)

    bytes32 constant private CLEARABLE_CONTRACT_NAME = "Clearable";

    /**
     * @dev Data structures (implemented in the eternal storage):
     * @dev _CLEARED_TRANSFER_IDS : string array with cleared transfer IDs
     * @dev _WALLETS_TO_DEBIT : address array with the addresses from which the funds should be taken
     * @dev _CLEARED_TRANSFER_REQUESTERS : address array with the addresses of the requesters of the payouts
     * @dev _CLEARED_TRANSFER_AMOUNTS : uint256 array with the cleared transfer amounts being requested
     * @dev _CLEARED_TRANSFER_INSTRUCTIONS : string array with the cleared transfer instructions (e.g. a reference to the bank account
     * to transfer the money to)
     * @dev _CLEARED_TRANSFER_STATUS_CODES : ClearedTransferRequestStatusCode array with the status code for the cleared transfer request
     * @dev _CLEARED_TRANSFER_IDS_INDEXES : mapping (address => mapping (string => uint256) storing the indexes for cleared transfer requests data
     * (this is to allow equal IDs to be used by different requesters)
     * @dev _CLEARED_TRANSFER_APPROVALS : mapping (address => mapping (address => bool)) storing the permissions for addresses
     * to request payouts on behalf of wallets
     */
    bytes32 constant private _CLEARED_TRANSFER_REQUESTERS =   "_clearedTransferRequesters";
    bytes32 constant private _CLEARED_TRANSFER_IDS =          "_clearedTransferIDs";
    bytes32 constant private _WALLETS_TO_DEBIT =    "_walletsToDebit";
    bytes32 constant private _CLEARED_TRANSFER_AMOUNTS =      "_clearedTransferAmounts";
    bytes32 constant private _CLEARED_TRANSFER_INSTRUCTIONS = "_clearedTransferInstructions";
    bytes32 constant private _CLEARED_TRANSFER_STATUS_CODES = "_clearedTransferStatusCodes";
    bytes32 constant private _CLEARED_TRANSFER_IDS_INDEXES =  "_clearedTransferIDsIndexes";
    bytes32 constant private _CLEARED_TRANSFER_APPROVALS =    "_clearedTransferApprovals";

    // Events

    event ClearedTransferRequested(
        address indexed requester,
        string indexed clearedTransferId,
        address indexed walletToDebit,
        uint256 amount,
        string instructions,
        uint256 index
    );

    event ClearedTransferRequestInProcess(address requester, string indexed clearedTransferId);

    event ClearedTransferRequestExecuted(address requester, string indexed clearedTransferId);

    event ClearedTransferRequestRejected(address requester, string indexed clearedTransferId, string reason);

    event ClearedTransferRequestCancelled(address requester, string indexed clearedTransferId);

    event ApprovalToRequestClearedTransfer(address indexed walletToDebit, address indexed requester);

    event RevokeApprovalToRequestClearedTransfer(address indexed walletToDebit, address indexed requester);

    // Constructor

    // Modifiers

    modifier clearedTransferRequestExists(address requester, string memory clearedTransferId) {
        require(_getClearedTransferIndex(requester, clearedTransferId) > 0, "ClearedTransfer request does not exist");
        _;
    }

    modifier clearedTransferRequestIndexExists(uint256 index) {
        require(index > 0 && index <= _manyClearedTransferRequests(), "ClearedTransfer request does not exist");
        _;
    }

    modifier clearedTransferRequestDoesNotExist(address requester, string memory clearedTransferId) {
        require(_getClearedTransferIndex(requester, clearedTransferId) == 0, "ClearedTransfer request already exists");
        _;
    }
    
    modifier clearedTransferRequestJustCreated(address requester, string memory clearedTransferId) {
        uint256 index = _getClearedTransferIndex(requester, clearedTransferId);
        require(_getClearedTransferStatus(index) == ClearedTransferRequestStatusCode.Requested, "ClearedTransfer request is already closed");
        _;
    }

    modifier clearedTransferRequestNotClosed(address requester, string memory clearedTransferId) {
        uint256 index = _getClearedTransferIndex(requester, clearedTransferId);
        ClearedTransferRequestStatusCode status = _getClearedTransferStatus(index);
        require(
            status == ClearedTransferRequestStatusCode.Requested || status == ClearedTransferRequestStatusCode.InProcess,
            "ClearedTransfer request not in process"
        );
        _;
    }

    // External state-modifying functions

    /**
     * @notice This function allows wallet owners to approve other addresses to request payouts on their behalf
     * @dev It is similar to the "approve" method in ERC20, but in this case no allowance is given and this is treated
     * as a "yes or no" flag
     * @param requester The address to be approved as potential issuer of cleared transfer requests
     */
    function approveToRequestClearedTransfer(address requester) external returns (bool) {
        address walletToDebit = msg.sender;
        _check(checkApproveToRequestClearedTransfer, walletToDebit, requester);
        return _approveToRequestClearedTransfer(walletToDebit, requester);
    }

    /**
     * @notice This function allows wallet owners to revoke cleared transfer request privileges from previously approved addresses
     * @param requester The address to be revoked as potential issuer of cleared transfer requests
     */
    function revokeApprovalToRequestClearedTransfer(address requester) external returns (bool) {
        address walletToDebit = msg.sender;
        return _revokeApprovalToRequestClearedTransfer(walletToDebit, requester);
    }

    /**
     * @notice Method for a wallet owner to request cleared transfer from the tokenizer on his/her own behalf
     * @param amount The amount requested
     * @param instructions The instructions for the cleared transfer request - e.g. routing information about the bank
     * account to which the funds should be directed (normally a hash / reference to the actual information
     * in an external repository), or a code to indicate that the tokenization entity should use the default
     * bank account associated with the wallet
     * @return The index of the entry of the new cleared transfer request in the internal array where it is stored
     */
    function requestClearedTransfer(string calldata clearedTransferId, uint256 amount, string calldata instructions)
        external
        returns (uint256 index)
    {
        address requester = msg.sender;
        address walletToDebit = msg.sender;
        _check(checkRequestClearedTransfer, walletToDebit, requester);
        index = _createClearedTransferRequest(requester, clearedTransferId, walletToDebit, amount, instructions);
    }

    /**
     * @notice Method to request cleared transfer on behalf of a (different) wallet owner (analogous to "transferFrom" in
     * classical ERC20). The requester needs to be previously approved
     * @param walletToDebit The address of the wallet from which the funds will be taken
     * @param amount The amount requested
     * @param instructions The debit instructions, as is "requestClearedTransfer"
     * @return The index of the entry of the new cleared transfer request in the internal array where it is stored
     */
    function requestClearedTransferFrom(string calldata clearedTransferId, address walletToDebit, uint256 amount, string calldata instructions)
        external
        returns (uint256 index)
    {
        address requester = msg.sender;
        _check(checkApproveToRequestClearedTransfer, walletToDebit, requester);
        require(_isApprovedToRequestClearedTransfer(walletToDebit, requester), "Not approved to request payout");
        index = _createClearedTransferRequest(requester, clearedTransferId, walletToDebit, amount, instructions);
    }

    /**
     * @notice Function to cancel an outstanding (i.e. not processed) cleared transfer request. Either the original requester
     * or the wallet owner can actually cancel an outstanding request
     * @dev In general the wallet owner should never need to cancel a cleared transfer request previousy sent by the requester,
     * but this possibility is provided just in case
     * @param clearedTransferId The ID of the cleared transfer request, which can then be used to index all the information about
     * the cleared transfer request (together with the address of the sender)
     */
    function cancelClearedTransferRequest(string calldata clearedTransferId) external
        clearedTransferRequestNotClosed(msg.sender, clearedTransferId)
        returns (bool)
    {
        address requester = msg.sender;
        uint256 index = _getClearedTransferIndex(requester, clearedTransferId);
        _setClearedTransferStatus(index, ClearedTransferRequestStatusCode.Cancelled);
        _finalizeHold(requester, clearedTransferId, HoldStatusCode.ReleasedByOperator);
        emit ClearedTransferRequestCancelled(requester, clearedTransferId);
        return true;
    }

    /**
     * @notice Function to be called by the tokenizer administrator to start processing a cleared transfer request. It simply
     * sets the status to "InProcess", which then prevents the requester from being able to cancel the payout
     * request. This method can be called by the operator to "lock" the cleared transfer request while the internal
     * transfers etc are done by the bank (offchain). It is not required though to call this method before
     * actually executing or rejecting the request, since the operator can call the executeClearedTransferRequest or the
     * rejectClearedTransferRequest directly, if desired.
     * @param requester The requester of the cleared transfer request
     * @param clearedTransferId The ID of the cleared transfer request, which can then be used to index all the information about
     * the cleared transfer request (together with the address of the sender)
     * @dev Only operator can do this
     * 
     */
    function processClearedTransferRequest(address requester, string calldata clearedTransferId) external
        clearedTransferRequestJustCreated(requester, clearedTransferId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index = _getClearedTransferIndex(requester, clearedTransferId);
        address walletToDebit = _getWalletToDebit(index);
        uint256 amount = _getClearedTransferAmount(index);
        _removeFunds(walletToDebit, amount);
        _increaseBalance(SUSPENSE_WALLET, amount);
        _setClearedTransferStatus(index, ClearedTransferRequestStatusCode.InProcess);
        _finalizeHold(requester, clearedTransferId, HoldStatusCode.ReleasedByOperator);
        emit ClearedTransferRequestInProcess(requester, clearedTransferId);
        return true;
    }

    /**
     * @notice Function to be called by the tokenizer administrator to honor a cleared transfer request. After crediting the
     * corresponding bank account, the administrator calls this method to close the request (as "Executed") and
     * burn the requested tokens from the relevant wallet
     * @param requester The requester of the cleared transfer request
     * @param clearedTransferId The ID of the cleared transfer request, which can then be used to index all the information about
     * the cleared transfer request (together with the address of the sender)
     * @dev Only operator can do this
     * 
     */
    function executeClearedTransferRequest(address requester, string calldata clearedTransferId) external
        clearedTransferRequestNotClosed(requester, clearedTransferId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index = _getClearedTransferIndex(requester, clearedTransferId);
        uint256 amount = _getClearedTransferAmount(index);
        _decreaseBalance(SUSPENSE_WALLET, amount);
        _setClearedTransferStatus(index, ClearedTransferRequestStatusCode.Executed);
        emit ClearedTransferRequestExecuted(requester, clearedTransferId);
        return true;
    }

    /**
     * @notice Function to be called by the tokenizer administrator to reject a cleared transfer request
     * @param requester The requester of the cleared transfer request
     * @param clearedTransferId The ID of the cleared transfer request, which can then be used to index all the information about
     * the cleared transfer request (together with the address of the sender)
     * @param reason A string field to provide a reason for the rejection, should this be necessary
     * @dev Only operator can do this
     * 
     */
    function rejectClearedTransferRequest(address requester, string calldata clearedTransferId, string calldata reason) external
        clearedTransferRequestNotClosed(requester, clearedTransferId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index = _getClearedTransferIndex(requester, clearedTransferId);
        address walletToDebit = _getWalletToDebit(index);
        uint256 amount = _getClearedTransferAmount(index);
        _addFunds(walletToDebit, amount);
        emit ClearedTransferRequestRejected(requester, clearedTransferId, reason);
        return _setClearedTransferStatus(index, ClearedTransferRequestStatusCode.Rejected);
    }

    // External view functions
    
    /**
     * @notice View method to read existing allowances to request payout
     * @param walletToDebit The address of the wallet from which the funds will be taken
     * @param requester The address that can request cleared transfer on behalf of the wallet owner
     * @return Whether the address is approved or not to request cleared transfer on behalf of the wallet owner
     */
    function isApprovedToRequestClearedTransfer(address walletToDebit, address requester) external view returns (bool) {
        return _isApprovedToRequestClearedTransfer(walletToDebit, requester);
    }

    /**
     * @notice Function to retrieve all the information available for a particular cleared transfer request
     * @param requester The requester of the cleared transfer request
     * @param clearedTransferId The ID of the cleared transfer request
     * @return index: the index of the array where the request is stored
     * @return walletToDebit: The address of the wallet from which the funds will be taken
     * @return amount: the amount of funds requested
     * @return instructions: the routing instructions to determine the destination of the funds being requested
     * @return status: the current status of the cleared transfer request
     */
    function retrieveClearedTransferData(address requester, string calldata clearedTransferId)
        external view
        returns (uint256 index, address walletToDebit, uint256 amount, string memory instructions, ClearedTransferRequestStatusCode status)
    {
        index = _getClearedTransferIndex(requester, clearedTransferId);
        walletToDebit = _getWalletToDebit(index);
        amount = _getClearedTransferAmount(index);
        instructions = _getClearedTransferInstructions(index);
        status = _getClearedTransferStatus(index);
    }

    /**
     * @notice Function to retrieve all the information available for a particular cleared transfer request
     * @param index The index of the cleared transfer request
     * @return requester: address that issued the cleared transfer request
     * @return clearedTransferId: the ID of the cleared transfer request (from this requester)
     * @return walletToDebit: The address of the wallet from which the funds will be taken
     * @return amount: the amount of funds requested
     * @return instructions: the routing instructions to determine the destination of the funds being requested
     * @return status: the current status of the cleared transfer request
     */
    function retrieveClearedTransferData(uint256 index)
        external view
        returns (address requester, string memory clearedTransferId, address walletToDebit, uint256 amount, string memory instructions, ClearedTransferRequestStatusCode status)
    {
        requester = _getClearedTransferRequester(index);
        clearedTransferId = _getClearedTransferID(index);
        walletToDebit = _getWalletToDebit(index);
        amount = _getClearedTransferAmount(index);
        instructions = _getClearedTransferInstructions(index);
        status = _getClearedTransferStatus(index);
    }

    /**
     * @notice This function returns the amount of cleared transfer requests outstanding and closed, since they are stored in an
     * array and the position in the array constitutes the ID of each cleared transfer request
     * @return The number of cleared transfer requests (both open and already closed)
     */
    function manyClearedTransferRequests() external view returns (uint256 many) {
        return _manyClearedTransferRequests();
    }

    // Internal functions

    // Private functions

    function _manyClearedTransferRequests() private view returns (uint256 many) {
        return getUintFromArray(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_IDS, 0);
    }

    function _getClearedTransferRequester(uint256 index) private view clearedTransferRequestIndexExists(index) returns (address requester) {
        requester = getAddressFromArray(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_REQUESTERS, index);
    }

    function _getClearedTransferIndex(
        address requester,
        string memory clearedTransferId
    )
        private view
        clearedTransferRequestExists(requester, clearedTransferId)
        returns (uint256 index)
    {
        index = getUintFromDoubleMapping(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_IDS_INDEXES, requester, clearedTransferId);
    }

    function _getClearedTransferID(uint256 index) private view clearedTransferRequestIndexExists(index) returns (string memory clearedTransferId) {
        clearedTransferId = getStringFromArray(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_IDS_INDEXES, index);
    }

    function _getWalletToDebit(uint256 index) private view clearedTransferRequestIndexExists(index) returns (address walletToDebit) {
        walletToDebit = getAddressFromArray(CLEARABLE_CONTRACT_NAME, _WALLETS_TO_DEBIT, index);
    }

    function _getClearedTransferAmount(uint256 index) private view clearedTransferRequestIndexExists(index) returns (uint256 amount) {
        amount = getUintFromArray(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_AMOUNTS, index);
    }

    function _getClearedTransferInstructions(uint256 index) private view clearedTransferRequestIndexExists(index) returns (string memory instructions) {
        instructions = getStringFromArray(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_INSTRUCTIONS, index);
    }

    function _getClearedTransferStatus(uint256 index) private view clearedTransferRequestIndexExists(index) returns (ClearedTransferRequestStatusCode status) {
        status = ClearedTransferRequestStatusCode(getUintFromArray(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_STATUS_CODES, index));
    }

    function _setClearedTransferStatus(uint256 index, ClearedTransferRequestStatusCode status) private clearedTransferRequestIndexExists(index) returns (bool) {
        return setUintInArray(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_STATUS_CODES, index, uint256(status));
    }

    function _approveToRequestClearedTransfer(address walletToDebit, address requester) private returns (bool) {
        emit ApprovalToRequestClearedTransfer(walletToDebit, requester);
        return setBoolInDoubleMapping(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_APPROVALS, walletToDebit, requester, true);
    }

    function _revokeApprovalToRequestClearedTransfer(address walletToDebit, address requester) private returns (bool) {
        emit RevokeApprovalToRequestClearedTransfer(walletToDebit, requester);
        return setBoolInDoubleMapping(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_APPROVALS, walletToDebit, requester, false);
    }

    function _isApprovedToRequestClearedTransfer(address walletToDebit, address requester) public view returns (bool){
        return getBoolFromDoubleMapping(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_APPROVALS, walletToDebit, requester);
    }

    function _createClearedTransferRequest(address requester, string memory clearedTransferId, address walletToDebit, uint256 amount, string memory instructions)
        private
        clearedTransferRequestDoesNotExist(requester, clearedTransferId)
        returns (uint256 index)
    {
        require(amount >= _availableFunds(walletToDebit), "Not enough funds to ask for payout");
        _createHold(clearedTransferId, msg.sender, walletToDebit, SUSPENSE_WALLET, SUSPENSE_WALLET, amount, 0);
        pushAddressToArray(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_REQUESTERS, requester);
        pushStringToArray(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_IDS, clearedTransferId);
        pushAddressToArray(CLEARABLE_CONTRACT_NAME, _WALLETS_TO_DEBIT, walletToDebit);
        pushUintToArray(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_AMOUNTS, amount);
        pushStringToArray(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_INSTRUCTIONS, instructions);
        pushUintToArray(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_STATUS_CODES, uint256(ClearedTransferRequestStatusCode.Requested));
        index = _manyClearedTransferRequests();
        setUintInDoubleMapping(CLEARABLE_CONTRACT_NAME, _CLEARED_TRANSFER_IDS_INDEXES, requester, clearedTransferId, index);
        emit ClearedTransferRequested(requester, clearedTransferId, walletToDebit, amount, instructions, index);
        return index;
    }

}
