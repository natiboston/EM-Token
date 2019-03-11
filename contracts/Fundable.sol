pragma solidity ^0.5;

import "./libraries/SafeMath.sol";
import "./Compliant.sol";

/**
 * @title Fundable
 * @notice Fundable provides ERC20-like token contracts with a workflow to request and honor funding requests from
 * external bank accounts. Funding requests are issued by wallet owners (or delegated to other requesters with a
 * "requestFrom" type of method), and requests are executed or rejected by the tokenizing entity (i.e. processed by
 * the owner of the overall contract)
 */
contract Fundable is Compliant {

    using SafeMath for uint256;

    enum FundingRequestStatusCode { Nonexistent, Requested, InProcess, Executed, Rejected, Cancelled }

    // Data structures (in eternal storage)

    bytes32 constant private FUNDABLE_CONTRACT_NAME = "Fundable";

    /**
     * @dev Data structures (implemented in the eternal storage):
     * @dev _FUNDING_IDS : string array with funding IDs
     * @dev _WALLETS_TO_FUND : address array with the addresses that should receive the funds requested
     * @dev _FUNDING_REQUESTERS : address array with the addresses of the requesters of the funds
     * @dev _FUNDING_AMOUNTS : uint256 array with the funding amounts being requested
     * @dev _FUNDING_INSTRUCTIONS : string array with the funding instructions (e.g. a reference to the bank account
     * to debit)
     * @dev _FUNDING_STATUS_CODES : FundingRequestStatusCode array with the status code for the funding request
     * @dev _FUNDING_IDS_INDEXES : mapping (address => mapping (string => uint256) storing the indexes for funding requests data
     * (this is to allow equal IDs to be used by different requesters)
     * @dev _FUNDING_APPROVALS : mapping (address => mapping (address => bool)) storing the permissions for addresses
     * to request funding on behalf of wallets
     */
    bytes32 constant private _FUNDING_REQUESTERS =   "_fundingRequesters";
    bytes32 constant private _FUNDING_IDS =          "_fundingIDs";
    bytes32 constant private _WALLETS_TO_FUND =      "_walletsToFund";
    bytes32 constant private _FUNDING_AMOUNTS =      "_fundingAmounts";
    bytes32 constant private _FUNDING_INSTRUCTIONS = "_fundingInstructions";
    bytes32 constant private _FUNDING_STATUS_CODES = "_fundingStatusCodes";
    bytes32 constant private _FUNDING_IDS_INDEXES =  "_fundingIDsIndexes";
    bytes32 constant private _FUNDING_APPROVALS =    "_fundingApprovals";

    // Events

    event FundingRequested(
        address indexed requester,
        string indexed fundingId,
        address indexed walletToFund,
        uint256 amount,
        string instructions,
        uint256 index
    );

    event FundingRequestInProcess(address requester, string indexed fundingId);

    event FundingRequestExecuted(address requester, string indexed fundingId);

    event FundingRequestRejected(address requester, string indexed fundingId, string reason);

    event FundingRequestCancelled(address requester, string indexed fundingId);

    event ApprovalToRequestFunding(address indexed walletToFund, address indexed requester);

    event RevokeApprovalToRequestFunding(address indexed walletToFund, address indexed requester);

    // Constructor

    // Modifiers

    modifier fundingRequestExists(address requester, string memory fundingId) {
        require(_getFundingIndex(requester, fundingId) > 0, "Funding request does not exist");
        _;
    }

    modifier fundingRequestIndexExists(uint256 index) {
        require(index > 0 && index <= _manyFundingRequests(), "Funding request does not exist");
        _;
    }

    modifier fundingRequestDoesNotExist(address requester, string memory fundingId) {
        require(_getFundingIndex(requester, fundingId) == 0, "Funding request already exists");
        _;
    }
    
    modifier fundingRequestJustCreated(address requester, string memory fundingId) {
        uint256 index = _getFundingIndex(requester, fundingId);
        require(_getFundingStatus(index) == FundingRequestStatusCode.Requested, "Funding request is already closed");
        _;
    }

    modifier fundingRequestNotClosed(address requester, string memory fundingId) {
        uint256 index = _getFundingIndex(requester, fundingId);
        FundingRequestStatusCode status = _getFundingStatus(index);
        require(
            status == FundingRequestStatusCode.Requested || status == FundingRequestStatusCode.InProcess,
            "Funding request not in process"
        );
        _;
    }

    // External state-modifying functions

    /**
     * @notice This function allows wallet owners to approve other addresses to request funding on their behalf
     * @dev It is similar to the "approve" method in ERC20, but in this case no allowance is given and this is treated
     * as a "yes or no" flag
     * @param requester The address to be approved as potential issuer of funding requests
     */
    function approveToRequestFunding(address requester) external returns (bool) {
        address walletToFund = msg.sender;
        _check(checkApproveToRequestFunding, walletToFund, requester);
        return _approveToRequestFunding(walletToFund, requester);
    }

    /**
     * @notice This function allows wallet owners to revoke funding request privileges from previously approved addresses
     * @param requester The address to be revoked as potential issuer of funding requests
     */
    function revokeApprovalToRequestFunding(address requester) external returns (bool) {
        address walletToFund = msg.sender;
        return _revokeApprovalToRequestFunding(walletToFund, requester);
    }

    /**
     * @notice Method for a wallet owner to request funding from the tokenizer on his/her own behalf
     * @param amount The amount requested
     * @param instructions The instructions for the funding request - e.g. routing information about the bank
     * account to be debited (normally a hash / reference to the actual information in an external repository),
     * or a code to indicate that the tokenization entity should use the default bank account associated with
     * the wallet
     * @return The index of the entry of the new funding request in the internal array where it is stored
     */
    function requestFunding(string calldata fundingId, uint256 amount, string calldata instructions)
        external
        returns (uint256 index)
    {
        address requester = msg.sender;
        address walletToFund = msg.sender;
        _check(checkRequestFunding, walletToFund, requester);
        index = _createFundingRequest(requester, fundingId, walletToFund, amount, instructions);
    }

    /**
     * @notice Method to request funding on behalf of a (different) wallet owner (analogous to "transferFrom" in
     * classical ERC20). The requester needs to be previously approved
     * @param walletToFund The address of the wallet which will receive the funding
     * @param amount The amount requested
     * @param instructions The debit instructions, as is "requestFunding"
     * @return The index of the entry of the new funding request in the internal array where it is stored
     */
    function requestFundingFrom(string calldata fundingId, address walletToFund, uint256 amount, string calldata instructions)
        external
        returns (uint256 index)
    {
        address requester = msg.sender;
        _check(checkApproveToRequestFunding, walletToFund, requester);
        require(_isApprovedToRequestFunding(walletToFund, requester), "Not approved to request funding");
        index = _createFundingRequest(requester, fundingId, walletToFund, amount, instructions);
    }

    /**
     * @notice Function to cancel an outstanding (i.e. not processed) funding request. Either the original requester
     * or the wallet owner can actually cancel an outstanding request, but only when the cancellation is done by the
     * requester the allowance is restored. When the owner cancels the request then the allowance is not restored,
     * and the wallet owner will need to approve a new allowance for the requester to use, if appropriate.
     * @dev In general the wallet owner should never need to cancel a funding request previousy sent by the requester,
     * but this possibility is provided just in case
     * @param fundingId The ID of the funding request, which can then be used to index all the information about
     * the funding request (together with the address of the sender)
     */
    function cancelFundingRequest(string calldata fundingId) external
        fundingRequestNotClosed(msg.sender, fundingId)
        returns (bool)
    {
        address requester = msg.sender;
        uint256 index = _getFundingIndex(requester, fundingId);
        _setFundingStatus(index, FundingRequestStatusCode.Cancelled);
        emit FundingRequestCancelled(requester, fundingId);
        return true;
    }

    /**
     * @notice Function to be called by the tokenizer administrator to start processing a funding request. It simply
     * sets the status to "InProcess", which then prevents the requester from being able to cancel the funding
     * request. This method can be called by the operator to "lock" the funding request while the internal
     * transfers etc are done by the bank (offchain). It is not required though to call this method before
     * actually executing or rejecting the request, since the operator can call the executeFundingRequest or the
     * rejectFundingRequest directly, if desired.
     * @param requester The requester of the funding request
     * @param fundingId The ID of the funding request, which can then be used to index all the information about
     * the funding request (together with the address of the sender)
     * @dev Only operator can do this
     * 
     */
    function processFundingRequest(address requester, string calldata fundingId) external
        fundingRequestJustCreated(requester, fundingId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index = _getFundingIndex(requester, fundingId);
        _setFundingStatus(index, FundingRequestStatusCode.InProcess);
        emit FundingRequestInProcess(requester, fundingId);
        return true;
    }

    /**
     * @notice Function to be called by the tokenizer administrator to honor a funding request. After debiting the
     * corresponding bank account, the administrator calls this method to close the request (as "Executed") and
     * mint the requested tokens into the relevant wallet
     * @param requester The requester of the funding request
     * @param fundingId The ID of the funding request, which can then be used to index all the information about
     * the funding request (together with the address of the sender)
     * @dev Only operator can do this
     * 
     */
    function executeFundingRequest(address requester, string calldata fundingId) external
        fundingRequestNotClosed(requester, fundingId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index = _getFundingIndex(requester, fundingId);
        address walletToFund = _getWalletToFund(index);
        uint256 amount = _getFundingAmount(index);
        _addFunds(walletToFund, amount);
        _setFundingStatus(index, FundingRequestStatusCode.Executed);
        emit FundingRequestExecuted(requester, fundingId);
        return true;
    }

    /**
     * @notice Function to be called by the tokenizer administrator to reject a funding request
     * @param requester The requester of the funding request
     * @param fundingId The ID of the funding request, which can then be used to index all the information about
     * the funding request (together with the address of the sender)
     * @param reason A string field to provide a reason for the rejection, should this be necessary
     * @dev Only operator can do this
     * 
     */
    function rejectFundingRequest(address requester, string calldata fundingId, string calldata reason) external
        fundingRequestNotClosed(requester, fundingId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index = _getFundingIndex(requester, fundingId);
        emit FundingRequestRejected(requester, fundingId, reason);
        return _setFundingStatus(index, FundingRequestStatusCode.Rejected);
    }

    // External view functions
    
    /**
     * @notice View method to read existing allowances to request funding
     * @param walletToFund The owner of the wallet that would receive the funding
     * @param requester The address that can request funding on behalf of the wallet owner
     * @return Whether the address is approved or not to request funding on behalf of the wallet owner
     */
    function isApprovedToRequestFunding(address walletToFund, address requester) external view returns (bool) {
        return _isApprovedToRequestFunding(walletToFund, requester);
    }

    /**
     * @notice Function to retrieve all the information available for a particular funding request
     * @param requester The requester of the funding request
     * @param fundingId The ID of the funding request
     * @return index: the index of the array where the request is stored
     * @return walletToFund: the wallet to which the requested funds are directed to
     * @return amount: the amount of funds requested
     * @return instructions: the routing instructions to determine the source of the funds being requested
     * @return status: the current status of the funding request
     */
    function retrieveFundingData(address requester, string calldata fundingId)
        external view
        returns (uint256 index, address walletToFund, uint256 amount, string memory instructions, FundingRequestStatusCode status)
    {
        index = _getFundingIndex(requester, fundingId);
        walletToFund = _getWalletToFund(index);
        amount = _getFundingAmount(index);
        instructions = _getFundingInstructions(index);
        status = _getFundingStatus(index);
    }

    /**
     * @notice Function to retrieve all the information available for a particular funding request
     * @param index The index of the funding request
     * @return requester: address that issued the funding request
     * @return fundingId: the ID of the funding request (from this requester)
     * @return walletToFund: the wallet to which the requested funds are directed to
     * @return amount: the amount of funds requested
     * @return instructions: the routing instructions to determine the source of the funds being requested
     * @return status: the current status of the funding request
     */
    function retrieveFundingData(uint256 index)
        external view
        returns (address requester, string memory fundingId, address walletToFund, uint256 amount, string memory instructions, FundingRequestStatusCode status)
    {
        requester = _getFundingRequester(index);
        fundingId = _getFundingID(index);
        walletToFund = _getWalletToFund(index);
        amount = _getFundingAmount(index);
        instructions = _getFundingInstructions(index);
        status = _getFundingStatus(index);
    }

    /**
     * @notice This function returns the amount of funding requests outstanding and closed, since they are stored in an
     * array and the position in the array constitutes the ID of each funding request
     * @return The number of funding requests (both open and already closed)
     */
    function manyFundingRequests() external view returns (uint256 many) {
        return _manyFundingRequests();
    }

    // Internal functions

    // Private functions

    function _manyFundingRequests() private view returns (uint256 many) {
        return getUintFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, 0);
    }

    function _getFundingRequester(uint256 index) private view fundingRequestIndexExists(index) returns (address requester) {
        requester = getAddressFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_REQUESTERS, index);
    }

    function _getFundingIndex(
        address requester,
        string memory fundingId
    )
        private view
        fundingRequestExists(requester, fundingId)
        returns (uint256 index)
    {
        index = getUintFromDoubleMapping(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS_INDEXES, requester, fundingId);
    }

    function _getFundingID(uint256 index) private view fundingRequestIndexExists(index) returns (string memory fundingId) {
        fundingId = getStringFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS_INDEXES, index);
    }

    function _getWalletToFund(uint256 index) private view fundingRequestIndexExists(index) returns (address walletToFund) {
        walletToFund = getAddressFromArray(FUNDABLE_CONTRACT_NAME, _WALLETS_TO_FUND, index);
    }

    function _getFundingAmount(uint256 index) private view fundingRequestIndexExists(index) returns (uint256 amount) {
        amount = getUintFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_AMOUNTS, index);
    }

    function _getFundingInstructions(uint256 index) private view fundingRequestIndexExists(index) returns (string memory instructions) {
        instructions = getStringFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_INSTRUCTIONS, index);
    }

    function _getFundingStatus(uint256 index) private view fundingRequestIndexExists(index) returns (FundingRequestStatusCode status) {
        status = FundingRequestStatusCode(getUintFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_STATUS_CODES, index));
    }

    function _setFundingStatus(uint256 index, FundingRequestStatusCode status) private fundingRequestIndexExists(index) returns (bool) {
        return setUintInArray(FUNDABLE_CONTRACT_NAME, _FUNDING_STATUS_CODES, index, uint256(status));
    }

    function _approveToRequestFunding(address walletToFund, address requester) private returns (bool) {
        emit ApprovalToRequestFunding(walletToFund, requester);
        return setBoolInDoubleMapping(FUNDABLE_CONTRACT_NAME, _FUNDING_APPROVALS, walletToFund, requester, true);
    }

    function _revokeApprovalToRequestFunding(address walletToFund, address requester) private returns (bool) {
        emit RevokeApprovalToRequestFunding(walletToFund, requester);
        return setBoolInDoubleMapping(FUNDABLE_CONTRACT_NAME, _FUNDING_APPROVALS, walletToFund, requester, false);
    }

    function _isApprovedToRequestFunding(address walletToFund, address requester) public view returns (bool){
        return getBoolFromDoubleMapping(FUNDABLE_CONTRACT_NAME, _FUNDING_APPROVALS, walletToFund, requester);
    }

    function _createFundingRequest(address requester, string memory fundingId, address walletToFund, uint256 amount, string memory instructions)
        private
        fundingRequestDoesNotExist(requester, fundingId)
        returns (uint256 index)
    {
        pushAddressToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_REQUESTERS, requester);
        pushStringToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, fundingId);
        pushAddressToArray(FUNDABLE_CONTRACT_NAME, _WALLETS_TO_FUND, walletToFund);
        pushUintToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_AMOUNTS, amount);
        pushStringToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_INSTRUCTIONS, instructions);
        pushUintToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_STATUS_CODES, uint256(FundingRequestStatusCode.Requested));
        index = _manyFundingRequests();
        setUintInDoubleMapping(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS_INDEXES, requester, fundingId, index);
        emit FundingRequested(requester, fundingId, walletToFund, amount, instructions, index);
        return index;
    }

}