pragma solidity ^0.5;

import "./libraries/SafeMath.sol";
import "./Compliant.sol";

/**
 * @title Payoutable
 * @notice Payoutable provides ERC20-like token contracts with a workflow to request and honor payout requests to
 * external bank accounts. Payout requests are issued by wallet owners (or delegated to other requesters with a
 * "requestFrom" type of method), and requests are executed or rejected by the tokenizing entity (i.e. processed by
 * the owner of the overall contract)
 */
contract Payoutable is Compliant {

    using SafeMath for uint256;

    enum PayoutRequestStatusCode { Nonexistent, Requested, InProcess, Executed, Rejected, Cancelled }

    // Data structures (in eternal storage)

    bytes32 constant private PAYOUTABLE_CONTRACT_NAME = "Payoutable";

    /**
     * @dev Data structures (implemented in the eternal storage):
     * @dev _PAYOUT_IDS : string array with payout IDs
     * @dev _WALLETS_TO_DEBIT : address array with the addresses from which the funds should be taken
     * @dev _PAYOUT_REQUESTERS : address array with the addresses of the requesters of the payouts
     * @dev _PAYOUT_AMOUNTS : uint256 array with the payout amounts being requested
     * @dev _PAYOUT_INSTRUCTIONS : string array with the payout instructions (e.g. a reference to the bank account
     * to transfer the money to)
     * @dev _PAYOUT_STATUS_CODES : PayoutRequestStatusCode array with the status code for the payout request
     * @dev _PAYOUT_IDS_INDEXES : mapping (address => mapping (string => uint256) storing the indexes for payout requests data
     * (this is to allow equal IDs to be used by different requesters)
     * @dev _PAYOUT_APPROVALS : mapping (address => mapping (address => bool)) storing the permissions for addresses
     * to request payouts on behalf of wallets
     */
    bytes32 constant private _PAYOUT_REQUESTERS =   "_payoutRequesters";
    bytes32 constant private _PAYOUT_IDS =          "_payoutIds";
    bytes32 constant private _WALLETS_TO_DEBIT =    "_walletsToDebit";
    bytes32 constant private _PAYOUT_AMOUNTS =      "_payoutAmounts";
    bytes32 constant private _PAYOUT_INSTRUCTIONS = "_payoutInstructions";
    bytes32 constant private _PAYOUT_STATUS_CODES = "_payoutStatusCodes";
    bytes32 constant private _PAYOUT_IDS_INDEXES =  "_payoutIdsIndexes";
    bytes32 constant private _PAYOUT_APPROVALS =    "_payoutApprovals";

    // Events

    event PayoutRequested(
        address indexed requester,
        string indexed transactionId,
        address indexed walletToDebit,
        uint256 amount,
        string instructions,
        uint256 index
    );

    event PayoutRequestInProcess(address requester, string indexed transactionId);

    event PayoutRequestExecuted(address requester, string indexed transactionId);

    event PayoutRequestRejected(address requester, string indexed transactionId, string reason);

    event PayoutRequestCancelled(address requester, string indexed transactionId);

    event ApprovalToRequestPayout(address indexed walletToDebit, address indexed requester);

    event RevokeApprovalToRequestPayout(address indexed walletToDebit, address indexed requester);

    // Constructor

    // Modifiers

    modifier payoutRequestExists(address requester, string memory transactionId) {
        require(_getPayoutIndex(requester, transactionId) > 0, "Payout request does not exist");
        _;
    }

    modifier payoutRequestIndexExists(uint256 index) {
        require(index > 0 && index <= _manyPayoutRequests(), "Payout request does not exist");
        _;
    }

    modifier payoutRequestDoesNotExist(address requester, string memory transactionId) {
        require(_getPayoutIndex(requester, transactionId) == 0, "Payout request already exists");
        _;
    }
    
    modifier payoutRequestJustCreated(address requester, string memory transactionId) {
        uint256 index = _getPayoutIndex(requester, transactionId);
        require(_getPayoutStatus(index) == PayoutRequestStatusCode.Requested, "Payout request is already closed");
        _;
    }

    modifier payoutRequestNotClosed(address requester, string memory transactionId) {
        uint256 index = _getPayoutIndex(requester, transactionId);
        PayoutRequestStatusCode status = _getPayoutStatus(index);
        require(
            status == PayoutRequestStatusCode.Requested || status == PayoutRequestStatusCode.InProcess,
            "Payout request not in process"
        );
        _;
    }

    // External state-modifying functions

    /**
     * @notice This function allows wallet owners to approve other addresses to request payouts on their behalf
     * @dev It is similar to the "approve" method in ERC20, but in this case no allowance is given and this is treated
     * as a "yes or no" flag
     * @param requester The address to be approved as potential issuer of payout requests
     */
    function approveToRequestPayout(address requester) external returns (bool) {
        address walletToDebit = msg.sender;
        _check(checkApproveToRequestPayout, walletToDebit, requester);
        return _approveToRequestPayout(walletToDebit, requester);
    }

    /**
     * @notice This function allows wallet owners to revoke payout request privileges from previously approved addresses
     * @param requester The address to be revoked as potential issuer of payout requests
     */
    function revokeApprovalToRequestPayout(address requester) external returns (bool) {
        address walletToDebit = msg.sender;
        return _revokeApprovalToRequestPayout(walletToDebit, requester);
    }

    /**
     * @notice Method for a wallet owner to request payout from the tokenizer on his/her own behalf
     * @param amount The amount requested
     * @param instructions The instructions for the payout request - e.g. routing information about the bank
     * account to which the funds should be directed (normally a hash / reference to the actual information
     * in an external repository), or a code to indicate that the tokenization entity should use the default
     * bank account associated with the wallet
     * @return The index of the entry of the new payout request in the internal array where it is stored
     */
    function requestPayout(string calldata transactionId, uint256 amount, string calldata instructions)
        external
        returns (uint256 index)
    {
        address requester = msg.sender;
        address walletToDebit = msg.sender;
        _check(checkRequestPayout, walletToDebit, requester, amount);
        index = _createPayoutRequest(requester, transactionId, walletToDebit, amount, instructions);
    }

    /**
     * @notice Method to request payout on behalf of a (different) wallet owner (analogous to "transferFrom" in
     * classical ERC20). The requester needs to be previously approved
     * @param walletToDebit The address of the wallet from which the funds will be taken
     * @param amount The amount requested
     * @param instructions The debit instructions, as is "requestPayout"
     * @return The index of the entry of the new payout request in the internal array where it is stored
     */
    function requestPayoutFrom(string calldata transactionId, address walletToDebit, uint256 amount, string calldata instructions)
        external
        returns (uint256 index)
    {
        address requester = msg.sender;
        _check(checkRequestPayout, walletToDebit, requester, amount);
        require(_isApprovedToRequestPayout(walletToDebit, requester), "Not approved to request payout");
        index = _createPayoutRequest(requester, transactionId, walletToDebit, amount, instructions);
    }

    /**
     * @notice Function to cancel an outstanding (i.e. not processed) payout request
     * @param transactionId The ID of the payout request, which can then be used to index all the information about
     * the payout request (together with the address of the sender)
     * @dev Only the original requester can actually cancel an outstanding request
     */
    function cancelPayoutRequest(string calldata transactionId) external
        payoutRequestNotClosed(msg.sender, transactionId)
        returns (bool)
    {
        address requester = msg.sender;
        uint256 index = _getPayoutIndex(requester, transactionId);
        _setPayoutStatus(index, PayoutRequestStatusCode.Cancelled);
        _finalizeHold(requester, transactionId, HoldStatusCode.ReleasedByOperator);
        emit PayoutRequestCancelled(requester, transactionId);
        return true;
    }

    /**
     * @notice Function to be called by the tokenizer administrator to start processing a payout request. First of all
     * it sets the status to "InProcess", which then prevents the requester from being able to cancel the payout
     * request. It also moves the funds to a suspense wallet, so the funds are locked until the payout request is
     * resolved. This method is inteded to be called by the operator to "lock" the payout request while the internal
     * transfers etc are done by the bank (offchain). It is not required though to call this method before
     * actually executing or rejecting the request, since the operator can call the executePayoutRequest or the
     * rejectPayoutRequest directly, if desired.
     * @param requester The requester of the payout request
     * @param transactionId The ID of the payout request, which can then be used to index all the information about
     * the payout request (together with the address of the sender)
     * @dev Only operator can do this
     * 
     */
    function processPayoutRequest(address requester, string calldata transactionId) external
        payoutRequestJustCreated(requester, transactionId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index = _getPayoutIndex(requester, transactionId);
        address walletToDebit = _getWalletToDebit(index);
        uint256 amount = _getPayoutAmount(index);
        _removeFunds(walletToDebit, amount);
        _increaseBalance(SUSPENSE_WALLET, amount);
        _setPayoutStatus(index, PayoutRequestStatusCode.InProcess);
        _finalizeHold(requester, transactionId, HoldStatusCode.ReleasedByOperator);
        emit PayoutRequestInProcess(requester, transactionId);
        return true;
    }

    /**
     * @notice Function to be called by the tokenizer administrator to honor a payout request. After crediting the
     * corresponding bank account, the administrator calls this method to close the request (as "Executed") and
     * burn the requested tokens from the relevant wallet
     * @param requester The requester of the payout request
     * @param transactionId The ID of the payout request, which can then be used to index all the information about
     * the payout request (together with the address of the sender)
     * @dev Only operator can do this
     * 
     */
    function executePayoutRequest(address requester, string calldata transactionId) external
        payoutRequestNotClosed(requester, transactionId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index = _getPayoutIndex(requester, transactionId);
        uint256 amount = _getPayoutAmount(index);
        _decreaseBalance(SUSPENSE_WALLET, amount);
        _setPayoutStatus(index, PayoutRequestStatusCode.Executed);
        emit PayoutRequestExecuted(requester, transactionId);
        return true;
    }

    /**
     * @notice Function to be called by the tokenizer administrator to reject a payout request
     * @param requester The requester of the payout request
     * @param transactionId The ID of the payout request, which can then be used to index all the information about
     * the payout request (together with the address of the sender)
     * @param reason A string field to provide a reason for the rejection, should this be necessary
     * @dev Only operator can do this
     * 
     */
    function rejectPayoutRequest(address requester, string calldata transactionId, string calldata reason) external
        payoutRequestNotClosed(requester, transactionId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index = _getPayoutIndex(requester, transactionId);
        address walletToDebit = _getWalletToDebit(index);
        uint256 amount = _getPayoutAmount(index);
        _addFunds(walletToDebit, amount);
        emit PayoutRequestRejected(requester, transactionId, reason);
        return _setPayoutStatus(index, PayoutRequestStatusCode.Rejected);
    }

    // External view functions
    
    /**
     * @notice View method to read existing allowances to request payout
     * @param walletToDebit The address of the wallet from which the funds will be taken
     * @param requester The address that can request payout on behalf of the wallet owner
     * @return Whether the address is approved or not to request payout on behalf of the wallet owner
     */
    function isApprovedToRequestPayout(address walletToDebit, address requester) external view returns (bool) {
        return _isApprovedToRequestPayout(walletToDebit, requester);
    }

    /**
     * @notice Function to retrieve all the information available for a particular payout request
     * @param requester The requester of the payout request
     * @param transactionId The ID of the payout request
     * @return index: the index of the array where the request is stored
     * @return walletToDebit: The address of the wallet from which the funds will be taken
     * @return amount: the amount of funds requested
     * @return instructions: the routing instructions to determine the destination of the funds being requested
     * @return status: the current status of the payout request
     */
    function retrievePayoutData(address requester, string calldata transactionId)
        external view
        returns (uint256 index, address walletToDebit, uint256 amount, string memory instructions, PayoutRequestStatusCode status)
    {
        index = _getPayoutIndex(requester, transactionId);
        walletToDebit = _getWalletToDebit(index);
        amount = _getPayoutAmount(index);
        instructions = _getPayoutInstructions(index);
        status = _getPayoutStatus(index);
    }

    /**
     * @notice Function to retrieve all the information available for a particular payout request
     * @param index The index of the payout request
     * @return requester: address that issued the payout request
     * @return transactionId: the ID of the payout request (from this requester)
     * @return walletToDebit: The address of the wallet from which the funds will be taken
     * @return amount: the amount of funds requested
     * @return instructions: the routing instructions to determine the destination of the funds being requested
     * @return status: the current status of the payout request
     */
    function retrievePayoutData(uint256 index)
        external view
        returns (address requester, string memory transactionId, address walletToDebit, uint256 amount, string memory instructions, PayoutRequestStatusCode status)
    {
        requester = _getPayoutRequester(index);
        transactionId = _gettransactionId(index);
        walletToDebit = _getWalletToDebit(index);
        amount = _getPayoutAmount(index);
        instructions = _getPayoutInstructions(index);
        status = _getPayoutStatus(index);
    }

    /**
     * @notice This function returns the amount of payout requests outstanding and closed, since they are stored in an
     * array and the position in the array constitutes the ID of each payout request
     * @return The number of payout requests (both open and already closed)
     */
    function manyPayoutRequests() external view returns (uint256 many) {
        return _manyPayoutRequests();
    }

    // Internal functions

    // Private functions

    function _manyPayoutRequests() private view returns (uint256 many) {
        return getUintFromArray(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_IDS, 0);
    }

    function _getPayoutRequester(uint256 index) private view payoutRequestIndexExists(index) returns (address requester) {
        requester = getAddressFromArray(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_REQUESTERS, index);
    }

    function _getPayoutIndex(
        address requester,
        string memory transactionId
    )
        private view
        payoutRequestExists(requester, transactionId)
        returns (uint256 index)
    {
        index = getUintFromDoubleMapping(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_IDS_INDEXES, requester, transactionId);
    }

    function _gettransactionId(uint256 index) private view payoutRequestIndexExists(index) returns (string memory transactionId) {
        transactionId = getStringFromArray(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_IDS_INDEXES, index);
    }

    function _getWalletToDebit(uint256 index) private view payoutRequestIndexExists(index) returns (address walletToDebit) {
        walletToDebit = getAddressFromArray(PAYOUTABLE_CONTRACT_NAME, _WALLETS_TO_DEBIT, index);
    }

    function _getPayoutAmount(uint256 index) private view payoutRequestIndexExists(index) returns (uint256 amount) {
        amount = getUintFromArray(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_AMOUNTS, index);
    }

    function _getPayoutInstructions(uint256 index) private view payoutRequestIndexExists(index) returns (string memory instructions) {
        instructions = getStringFromArray(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_INSTRUCTIONS, index);
    }

    function _getPayoutStatus(uint256 index) private view payoutRequestIndexExists(index) returns (PayoutRequestStatusCode status) {
        status = PayoutRequestStatusCode(getUintFromArray(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_STATUS_CODES, index));
    }

    function _setPayoutStatus(uint256 index, PayoutRequestStatusCode status) private payoutRequestIndexExists(index) returns (bool) {
        return setUintInArray(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_STATUS_CODES, index, uint256(status));
    }

    function _approveToRequestPayout(address walletToDebit, address requester) private returns (bool) {
        emit ApprovalToRequestPayout(walletToDebit, requester);
        return setBoolInDoubleMapping(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_APPROVALS, walletToDebit, requester, true);
    }

    function _revokeApprovalToRequestPayout(address walletToDebit, address requester) private returns (bool) {
        emit RevokeApprovalToRequestPayout(walletToDebit, requester);
        return setBoolInDoubleMapping(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_APPROVALS, walletToDebit, requester, false);
    }

    function _isApprovedToRequestPayout(address walletToDebit, address requester) public view returns (bool){
        return getBoolFromDoubleMapping(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_APPROVALS, walletToDebit, requester);
    }

    function _createPayoutRequest(address requester, string memory transactionId, address walletToDebit, uint256 amount, string memory instructions)
        private
        payoutRequestDoesNotExist(requester, transactionId)
        returns (uint256 index)
    {
        require(amount >= _availableFunds(walletToDebit), "Not enough funds to ask for payout");
        _createHold(transactionId, requester, walletToDebit, SUSPENSE_WALLET, address(0), amount, false, 0);
        pushAddressToArray(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_REQUESTERS, requester);
        pushStringToArray(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_IDS, transactionId);
        pushAddressToArray(PAYOUTABLE_CONTRACT_NAME, _WALLETS_TO_DEBIT, walletToDebit);
        pushUintToArray(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_AMOUNTS, amount);
        pushStringToArray(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_INSTRUCTIONS, instructions);
        pushUintToArray(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_STATUS_CODES, uint256(PayoutRequestStatusCode.Requested));
        index = _manyPayoutRequests();
        setUintInDoubleMapping(PAYOUTABLE_CONTRACT_NAME, _PAYOUT_IDS_INDEXES, requester, transactionId, index);
        emit PayoutRequested(requester, transactionId, walletToDebit, amount, instructions, index);
        return index;
    }

}
