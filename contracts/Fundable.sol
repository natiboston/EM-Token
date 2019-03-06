pragma solidity ^0.5;

import "./libraries/SafeMath.sol";
import "./Compliant.sol";

/**
 * @title Fundable
 * @notice Fundable provides ERC20 token contracts with a workflow to request and honor funding requests from external
 * bank accounts. Funding requests are issued by wallet owners (or delegated to other requesters with a "requestFrom"
 * type of method), and requests are executed or rejected by the tokenizing entity (i.e. called by the owner of the
 * overall contract)
 */
contract Fundable is Compliant {

    using SafeMath for uint256;

    enum FundingRequestStatusCode { Nonexistent, Requested, Executed, Rejected, Cancelled }

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
     * @dev _FUNDING_IDS_INDEXES : mapping (string => uint256) storing the indexes for funding requests data
     * @dev _ALLOWED_TO_REQUEST_FUNDING : mapping (address => mapping (address => uint256)) with the allowances
     * to perform funding requests
     */
    bytes32 constant private _FUNDING_IDS = "_fudndingIDs";
    bytes32 constant private _WALLETS_TO_FUND = "_walletsToFund";
    bytes32 constant private _FUNDING_REQUESTERS = "_fundingRequesters";
    bytes32 constant private _FUNDING_AMOUNTS = "_FundingAmounts";
    bytes32 constant private _FUNDING_INSTRUCTIONS = "_FundingInstructions";
    bytes32 constant private _FUNDING_STATUS_CODES = "_fundingStatusCodes";
    bytes32 constant private _FUNDING_IDS_INDEXES = "_fundingIDsIndexes";
    bytes32 constant private _ALLOWED_TO_REQUEST_FUNDING = "_allowedToRequestFunding";

    // Events

    event FundingRequested(
        string indexed fundingId,
        address indexed walletToFund,
        address indexed requester,
        uint256 amount,
        string instructions,
        uint256 index
    );

    event FundingRequestExecuted(string indexed fundingId);

    event FundingRequestRejected(string indexed fundingId, string reason);

    event FundingRequestCancelled(string indexed fundingId);

    event ApprovalToRequestFunding(address indexed walletToFund, address indexed requester, uint256 value);

    // Constructor

    // Modifiers

    modifier fundingRequestExists(string memory fundingId) {
        require(_getFundingIndex(fundingId) == 0, "Funding request does not exist");
        _;
    }

    modifier fundingRequestIndexExists(uint256 index) {
        require(index > 0 && index <= manyFundingRequests(), "Funding request does not exist");
        _;
    }

    modifier fundingRequestDoesNotExist(string memory fundingId) {
        require(_getFundingIndex(fundingId) == 0, "Funding request already exists");
        _;
    }
    
    modifier fundingRequestNotClosed(string memory fundingId) {
        require(_getFundingStatus(_getFundingIndex(fundingId)) == FundingRequestStatusCode.Requested, "Funding request is already closed");
        _;
    }

    modifier fundingRequesterOnly(string memory fundingId) {
        require(msg.sender == _getFundingRequester(_getFundingIndex(fundingId)), "Sender is not the requester");
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
        fundingRequestDoesNotExist(fundingId)
        returns (uint256 index)
    {
        index = _createFundingRequest(fundingId, msg.sender, msg.sender, amount, instructions);
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
        fundingRequestDoesNotExist(fundingId)
        returns (uint256 index)
    {
        // This will throw if the requester is not previously allowed due to the protection of the ".sub" method. This
        // is the only check that the requester is actually approved to do so
        uint256 currentAllowance = _getAllowanceToRequestFunding(walletToFund, msg.sender);
        _approveToRequestFunding(walletToFund, msg.sender, currentAllowance.sub(amount));
        index = _createFundingRequest(fundingId, walletToFund, msg.sender, amount, instructions);
    }

    /**
     * @dev Function to cancel an outstanding (i.e. not processed) funding request. Either the original requester
     * or the wallet owner can actually cancel an outstanding request, but only when the cancellation is done by the
     * requester the allowance is restored. When the owner cancels the request then the allowance is not restored,
     * and the wallet owner will need to approve a new allowance for the requester to use, if appropriate.
     * @dev In general the wallet owner should never need to cancel a funding request previousy sent by the requester,
     * but this possibility is provided just in case
     * @param fundingId The ID of the funding request, which can then be used to index all the information about
     * the funding request
     */
    function cancelFundingRequest(string memory fundingId) public
        fundingRequestNotClosed(fundingId)
        fundingRequesterOnly(fundingId)
        returns (bool)
    {
        uint256 index;
        address walletToFund;
        address requester;
        uint256 amount;
        string memory instructions;
        FundingRequestStatusCode status;
        (index, walletToFund, requester, amount, instructions, status) = retrieveFundingData(fundingId);
        _setFundingStatus(_getFundingIndex(fundingId), FundingRequestStatusCode.Cancelled);
        if(walletToFund != requester) {
            _approveToRequestFunding(walletToFund, requester, allowanceToRequestFunding(walletToFund, requester).add(amount));
        }
        emit FundingRequestCancelled(fundingId);
        return true;
    }

    /**
     * @dev Function to be called by the tokenizer administrator to honor a funding request. After debiting the
     * corresponding bank account, the administrator calls this method to close the request (as "Executed") and
     * mint the requested tokens into the relevant wallet
     * @param fundingId The ID of the request, which contains all the relevant information such as the amount
     * requested and the address of the wallet that receives the tokens
     * @dev Only operator can do this
     * 
     */
    function executeFundingRequest(string memory fundingId) public
        fundingRequestNotClosed(fundingId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        // To do: add funding to overdraft / balance
        uint256 index;
        address walletToFund;
        address requester;
        uint256 amount;
        string memory instructions;
        FundingRequestStatusCode status;
        (index, walletToFund, requester, amount, instructions, status) = retrieveFundingData(fundingId);
        _setFundingStatus(_getFundingIndex(fundingId), FundingRequestStatusCode.Executed);
        emit FundingRequestExecuted(fundingId);
        return true;
    }

    /**
     * @dev Function to be called by the tokenizer administrator to reject a funding request. When the administrator
     * calls this method the request will be closed (as "Executed") and the tokens will be minted into the relevant
     * wallet. If the request was submitted by an address different to the wallet's owner, then the allowance will be
     * restored
     * @param fundingId The ID of the request, which contains all the relevant information such as the amount
     * requested and the address of the wallet that receives the tokens
     * @param reason A string field to provide a reason for the rejection, should this be necessary
     * @dev Only operator can do this
     * 
     */
    function rejectFundingRequest(string memory fundingId, string memory reason) public
        fundingRequestNotClosed(fundingId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 index;
        address walletToFund;
        address requester;
        uint256 amount;
        string memory instructions;
        FundingRequestStatusCode status;
        (index, walletToFund, requester, amount, instructions, status) = retrieveFundingData(fundingId);
        _setFundingStatus(_getFundingIndex(fundingId), FundingRequestStatusCode.Rejected);
        if(walletToFund != requester) {
            _approveToRequestFunding(walletToFund, requester, allowanceToRequestFunding(walletToFund, requester).add(amount));
        }
        emit FundingRequestRejected(fundingId, reason);
        return true;
    }

    /**
     * @dev Function to retrieve all the information available for a particular funding request
     * @param fundingId The ID of the funding request
     */
    function retrieveFundingData(string memory fundingId)
        public view
        returns (uint256 index, address walletToFund, address requester, uint256 amount, string memory instructions, FundingRequestStatusCode status)
    {
        index = _getFundingIndex(fundingId);
        walletToFund = _getWalletToFund(index);
        requester = _getFundingRequester(index);
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
        returns (string memory fundingId, address walletToFund, address requester, uint256 amount, string memory instructions, FundingRequestStatusCode status)
    {
        fundingId = _getFundingID(index);
        walletToFund = _getWalletToFund(index);
        requester = _getFundingRequester(index);
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

    function _getFundingIndex(string memory fundingId) private view fundingRequestExists(fundingId) returns (uint256) {
        return getUintFromMapping(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS_INDEXES, fundingId);
    }

    function _getFundingID(uint256 index) private view fundingRequestIndexExists(index) returns (string memory) {
        return getStringFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS_INDEXES, index);
    }

    function _getWalletToFund(uint256 index) private view fundingRequestIndexExists(index) returns (address) {
        return getAddressFromArray(FUNDABLE_CONTRACT_NAME, _WALLETS_TO_FUND, index);
    }

    function _getFundingRequester(uint256 index) private view fundingRequestIndexExists(index) returns (address) {
        return getAddressFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_REQUESTERS, index);
    }

    function _getFundingAmount(uint256 index) private view fundingRequestIndexExists(index) returns (uint256) {
        return getUintFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_AMOUNTS, index);
    }

    function _getFundingInstructions(uint256 index) private view fundingRequestIndexExists(index) returns (string memory) {
        return getStringFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_INSTRUCTIONS, index);
    }

    function _getFundingStatus(uint256 index) private view fundingRequestIndexExists(index) returns (FundingRequestStatusCode) {
        return FundingRequestStatusCode(getUintFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_STATUS_CODES, index));
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

    function _createFundingRequest(string memory fundingId, address walletToFund, address requester, uint256 amount, string memory instructions)
        private
        returns (uint256)
    {
        pushStringToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, fundingId);
        pushAddressToArray(FUNDABLE_CONTRACT_NAME, _WALLETS_TO_FUND, walletToFund);
        pushAddressToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_REQUESTERS, requester);
        pushUintToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_AMOUNTS, amount);
        pushStringToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_INSTRUCTIONS, instructions);
        pushUintToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_STATUS_CODES, uint256(FundingRequestStatusCode.Requested));
        uint256 index = manyFundingRequests();
        setUintInMapping(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS_INDEXES, fundingId, index);
        emit FundingRequested(fundingId, walletToFund, requester, amount, instructions, index);
        return index;
    }

}