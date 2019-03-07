pragma solidity ^0.5;

import "./libraries/SafeMath.sol";
import "./Compliant.sol";

/**
 * @title Fundable
 * @notice Fundable provides ERC20-like  token contracts with a workflow to request and honor funding requests from
 * external bank accounts. Funding requests are issued by wallet owners (or delegated to other requesters with a
 * "requestFrom" type of method), and requests are executed or rejected by the tokenizing entity (i.e. called by the
 * owner of the overall contract)
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
     * @dev _ALLOWED_TO_REQUEST_FUNDING : mapping (address => mapping (address => uint256)) with the allowances
     * to perform funding requests ( allowances are indexed [walletToFund][requester] )
     */
    bytes32 constant private _FUNDING_REQUESTERS = "_fundingRequesters";
    bytes32 constant private _FUNDING_IDS = "_fudndingIDs";
    bytes32 constant private _WALLETS_TO_FUND = "_walletsToFund";
    bytes32 constant private _FUNDING_AMOUNTS = "_FundingAmounts";
    bytes32 constant private _FUNDING_INSTRUCTIONS = "_FundingInstructions";
    bytes32 constant private _FUNDING_STATUS_CODES = "_fundingStatusCodes";
    bytes32 constant private _FUNDING_IDS_INDEXES = "_fundingIDsIndexes";
    bytes32 constant private _ALLOWED_TO_REQUEST_FUNDING = "_allowedToRequestFunding";

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

    event ApprovalToRequestFunding(address indexed walletToFund, address indexed requester, uint256 value);

    // Constructor

    // Modifiers

    modifier fundingRequestExists(address requester, string memory fundingId) {
        require(_getFundingIndex(requester, fundingId) > 0, "Funding request does not exist");
        _;
    }

    modifier fundingRequestIndexExists(uint256 index) {
        require(index > 0 && index <= manyFundingRequests(), "Funding request does not exist");
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

    // Interface functions

    /**
     * @dev Method to approve other address to request funding on behalf of a wallet owner (analogous to "approve" in
     * ERC20 transfers)
     * @param requester The address that will be requesting funding on behalf of the wallet owner
     * @param amount The amount of the allowance
     * @notice (TO DO: add increase / decrease alloance approval methods)
     */
    function approveToRequestFunding(address requester, uint256 amount) public returns (bool) {
        return _approveToRequestFunding(msg.sender, requester, amount);
    }

    /**
     * @dev View method to read existing allowances to request funding
     * @param walletToFund The owner of the wallet that would receive the funding
     * @param requester The address that can request funding on behalf of the wallet owner
     */
    function allowanceToRequestFunding(address walletToFund, address requester) public view returns (uint256) {
        return _getAllowanceToRequestFunding(walletToFund, requester);
    }

    /**
     * @dev Method for a wallet owner to request funding from the tokenizer on his/her own behalf
     * @param amount The amount requested
     * @param instructions The instructions for the funding request - e.g. routing information about the bank
     * account to be debited (normally a hash / reference to the actual information in an external repository),
     * or a code to indicate that the tokenization entity should use the default bank account associated with
     * the wallet
     */
    function requestFunding(string memory fundingId, uint256 amount, string memory instructions)
        public
        returns (uint256 index)
    {
        address requester = msg.sender;
        address walletToFund = msg.sender;
        index = _createFundingRequest(requester, fundingId, walletToFund, amount, instructions);
    }

    /**
     * @dev Method to request funding on behalf of a (different) wallet owner (analogous to "transferFrom" in
     * classical ERC20). An allowance to request funding on behalf of the wallet owner needs to be previously approved
     * @param walletToFund The address of the wallet which will receive the funding
     * @param amount The amount requested
     * @param instructions The debit instructions, as is "requestFunding"
     */
    function requestFundingFrom(string memory fundingId, address walletToFund, uint256 amount, string memory instructions)
        public
        returns (uint256 index)
    {
        address requester = msg.sender;
        // This will throw if the requester is not previously allowed due to the protection of the ".sub" method. This
        // is the only check that the requester is actually approved to do so
        uint256 currentAllowance = _getAllowanceToRequestFunding(walletToFund, requester);
        _approveToRequestFunding(walletToFund, requester, currentAllowance.sub(amount));
        index = _createFundingRequest(requester, fundingId, walletToFund, amount, instructions);
    }

    /**
     * @dev Function to cancel an outstanding (i.e. not processed) funding request. Either the original requester
     * or the wallet owner can actually cancel an outstanding request, but only when the cancellation is done by the
     * requester the allowance is restored. When the owner cancels the request then the allowance is not restored,
     * and the wallet owner will need to approve a new allowance for the requester to use, if appropriate.
     * @dev In general the wallet owner should never need to cancel a funding request previousy sent by the requester,
     * but this possibility is provided just in case
     * @param fundingId The ID of the funding request, which can then be used to index all the information about
     * the funding request (together with the address of the sender)
     */
    function cancelFundingRequest(string memory fundingId) public
        fundingRequestNotClosed(msg.sender, fundingId)
        returns (bool)
    {
        address requester = msg.sender;
        uint256 index;
        address walletToFund;
        uint256 amount;
        string memory instructions;
        FundingRequestStatusCode status;
        (index, walletToFund, amount, instructions, status) = retrieveFundingData(requester, fundingId);
        _setFundingStatus(index, FundingRequestStatusCode.Cancelled);
        if(walletToFund != requester) {
            _approveToRequestFunding(walletToFund, requester, allowanceToRequestFunding(walletToFund, requester).add(amount));
        }
        emit FundingRequestCancelled(requester, fundingId);
        return true;
    }

    /**
     * @dev Function to be called by the tokenizer administrator to start processing a funding request. It simply
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
    function processFundingRequest(address requester, string memory fundingId) public
        fundingRequestJustCreated(msg.sender, fundingId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index = _getFundingIndex(requester, fundingId);
        _setFundingStatus(index, FundingRequestStatusCode.InProcess);
        emit FundingRequestInProcess(requester, fundingId);
        return true;
    }

    /**
     * @dev Function to be called by the tokenizer administrator to honor a funding request. After debiting the
     * corresponding bank account, the administrator calls this method to close the request (as "Executed") and
     * mint the requested tokens into the relevant wallet
     * @param requester The requester of the funding request
     * @param fundingId The ID of the funding request, which can then be used to index all the information about
     * the funding request (together with the address of the sender)
     * @dev Only operator can do this
     * 
     */
    function executeFundingRequest(address requester, string memory fundingId) public
        fundingRequestNotClosed(msg.sender, fundingId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index;
        address walletToFund;
        uint256 amount;
        string memory instructions;
        FundingRequestStatusCode status;
        (index, walletToFund, amount, instructions, status) = retrieveFundingData(requester, fundingId);
        uint256 amountDrawn = _drawnAmount(walletToFund);
        if (amount <= amountDrawn) {
            _restoreOverdraft(walletToFund, amount);
        } else {
            _restoreOverdraft(walletToFund, amountDrawn);
            _increaseBalance(walletToFund, amount - amountDrawn);
        }
        _setFundingStatus(index, FundingRequestStatusCode.Executed);
        emit FundingRequestExecuted(requester, fundingId);
        return true;
    }

    /**
     * @dev Function to be called by the tokenizer administrator to reject a funding request. When the administrator
     * calls this method the request will be closed (as "Executed") and the tokens will be minted into the relevant
     * wallet. If the request was submitted by an address different to the wallet's owner, then the allowance will be
     * restored
     * @param requester The requester of the funding request
     * @param fundingId The ID of the funding request, which can then be used to index all the information about
     * the funding request (together with the address of the sender)
     * @param reason A string field to provide a reason for the rejection, should this be necessary
     * @dev Only operator can do this
     * 
     */
    function rejectFundingRequest(address requester, string memory fundingId, string memory reason) public
        fundingRequestNotClosed(requester, fundingId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index;
        address walletToFund;
        uint256 amount;
        string memory instructions;
        FundingRequestStatusCode status;
        (index, walletToFund, amount, instructions, status) = retrieveFundingData(requester, fundingId);
        _adjustAllowances(walletToFund, requester, amount);
        emit FundingRequestRejected(requester, fundingId, reason);
        return _setFundingStatus(index, FundingRequestStatusCode.Rejected);
    }

    /**
     * @dev Function to retrieve all the information available for a particular funding request
     * @param requester The requester of the funding request
     * @param fundingId The ID of the funding request
     */
    function retrieveFundingData(address requester, string memory fundingId)
        public view
        returns (uint256 index, address walletToFund, uint256 amount, string memory instructions, FundingRequestStatusCode status)
    {
        index = _getFundingIndex(requester, fundingId);
        walletToFund = _getWalletToFund(index);
        amount = _getFundingAmount(index);
        instructions = _getFundingInstructions(index);
        status = _getFundingStatus(index);
    }

    /**
     * @dev Function to retrieve all the information available for a particular funding request requested
     * by msg.sender
     * @param fundingId The ID of the funding request
     */
    function retrieveFundingData(string memory fundingId)
        public view
        returns (uint256 index, address walletToFund, uint256 amount, string memory instructions, FundingRequestStatusCode status)
    {
        address requester = msg.sender;
        index = _getFundingIndex(requester, fundingId);
        walletToFund = _getWalletToFund(index);
        amount = _getFundingAmount(index);
        instructions = _getFundingInstructions(index);
        status = _getFundingStatus(index);
    }

    /**
     * @dev Function to retrieve all the information available for a particular funding request
     * @param index The index of the funding request
     */
    function retrieveFundingData(uint256 index)
        public view
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
     * @dev This function returns the amount of funding requests outstanding and closed, since they are stored in an
     * array and the position in the array constitutes the ID of each funding request
     */
    function manyFundingRequests() public view returns (uint256 many) {
        return getUintFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, 0);
    }

    // Internal functions

    // Private functions

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

    function _getAllowanceToRequestFunding(address walletToFund, address requester) public view returns (uint){
        return getUintFromDoubleMapping(FUNDABLE_CONTRACT_NAME, _ALLOWED_TO_REQUEST_FUNDING, walletToFund, requester);
    }

    function _setAllowanceToRequestFunding(address walletToFund, address requester, uint256 value) public returns (bool){
        return setUintInDoubleMapping(FUNDABLE_CONTRACT_NAME, _ALLOWED_TO_REQUEST_FUNDING, walletToFund, requester, value);
    }

    function _approveToRequestFunding(address walletToFund, address requester, uint256 amount) private returns (bool) {
        emit ApprovalToRequestFunding(walletToFund, requester, amount);
        return _setAllowanceToRequestFunding(walletToFund, requester, amount);
    }

    // This just to avoid stack too deep problems
    function _adjustAllowances(address walletToFund, address requester, uint256 amount) private {
        if(walletToFund != requester) {
            uint256 currentAllowance = _getAllowanceToRequestFunding(walletToFund, requester);
            uint256 newAllowance = currentAllowance.add(amount);
            _approveToRequestFunding(walletToFund, requester, newAllowance);
        }
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
        index = manyFundingRequests();
        setUintInDoubleMapping(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS_INDEXES, requester, fundingId, index);
        emit FundingRequested(requester, fundingId, walletToFund, amount, instructions, index);
    }

}