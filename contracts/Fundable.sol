pragma solidity ^0.5;

import "./RoleControlled.sol";
import "./abstracts/AFundable.sol";
import "./libraries/SafeMath.sol";

contract Fundable is AFundable, RoleControlled {

    using SafeMath for uint256;

    bytes32 constant internal FUNDABLE_CONTRACT_NAME = "Fundable";

    /**
     * @dev Data structures for funding requests (implemented in the eternal storage):
     * @dev _FUNDING_IDS : bytes32 array with funding IDs
     * @dev _WALLETS_TO_FUND : address array with the addresses that should receive the funds requested
     * @dev _REQUESTERS : address array with the addresses of the requesters of the funds
     * @dev _AMOUNTS : uint256 array with the funding amounts being requested
     * @dev _INSTRUCTIONS : string array with the funding instructions (e.g. a reference to the bank account
     * to debit)
     * @dev _STATUS_CODES : FundingRequestStatusCode array with the status code for the funding request
     * @dev _FUNDING_IDS_INDICES : mapping (string => uint256) storing the indexes for funding requests data
     * @dev _ALLOWED_TO_REQUEST_FUNDING : mapping (address => mapping (address => uint256)) with the allowances
     * to perform funding requests
     */
    bytes32 constant internal _FUNDING_IDS = "_fudndingIDs";
    bytes32 constant internal _WALLETS_TO_FUND = "_walletsToFund";
    bytes32 constant internal _REQUESTERS = "_requesters";
    bytes32 constant internal _AMOUNTS = "_amounts";
    bytes32 constant internal _INSTRUCTIONS = "_instructions";
    bytes32 constant internal _STATUS_CODES = "_statusCode";
    bytes32 constant internal _FUNDING_IDS_INDICES = "_fundingIDsIndices";
    bytes32 constant internal _ALLOWED_TO_REQUEST_FUNDING = "_allowedToRequestFunding";

    // Utility functions
    
    function _getIndex(string memory fundingId) private view returns (uint256) {
        uint256 index = getUintFromMapping(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS_INDICES, fundingId);
        require(index > 0, "Funding request does not exist");
        return index;
    }

    function _getWalletToFund(string memory fundingId) private view returns (address) {
        return getAddressFromArray(FUNDABLE_CONTRACT_NAME, _WALLETS_TO_FUND, _getIndex(fundingId));
    }

    function _getRequester(string memory fundingId) private view returns (address) {
        return getAddressFromArray(FUNDABLE_CONTRACT_NAME, _REQUESTERS, _getIndex(fundingId));
    }

    function _getAmount(string memory fundingId) private view returns (uint256) {
        return getUintFromArray(FUNDABLE_CONTRACT_NAME, _AMOUNTS, _getIndex(fundingId));
    }

    function _getInstructions(string memory fundingId) private view returns (string memory) {
        return getStringFromArray(FUNDABLE_CONTRACT_NAME, _INSTRUCTIONS, _getIndex(fundingId));
    }

    function _getStatus(string memory fundingId) private view returns (FundingRequestStatusCode) {
        return FundingRequestStatusCode(getUintFromArray(FUNDABLE_CONTRACT_NAME, _STATUS_CODES, _getIndex(fundingId)));
    }

    // Modifiers

    modifier fundingRequestNotClosed(string memory fundingId) {
        require(_getStatus(fundingId) == FundingRequestStatusCode.Requested, "Funding request is already closed");
        _;
    }

    modifier fundingRequesterOnly(string memory fundingId) {
        require(msg.sender == _getRequester(fundingId), "Sender is not the requester");
        _;
    }

    // Now to the actual implementation:

    function approveToRequestFunding(address requester, uint256 amount) public returns (bool) {
        return _approveToRequestFunding(msg.sender, requester, amount);
    }

    function _approveToRequestFunding(address walletToFund, address requester, uint256 amount) private returns (bool) {
        setUintInDoubleMapping(FUNDABLE_CONTRACT_NAME, _ALLOWED_TO_REQUEST_FUNDING, walletToFund, requester, amount);
        emit ApprovalToRequestFunding(walletToFund, requester, amount);
        return true;
    }

    function allowanceToRequestFunding(address walletToFund, address requester) public view returns (uint256) {
        return getUintFromDoubleMapping(FUNDABLE_CONTRACT_NAME, _ALLOWED_TO_REQUEST_FUNDING, walletToFund, requester);
    }

    function requestFunding(string memory fundingId, uint256 amount, string memory instructions) public returns (bool) {
        return _requestFunding(fundingId, msg.sender, msg.sender, amount, instructions);
    }

    function requestFundingFrom(string memory fundingId, address walletToFund, uint256 amount, string memory instructions)
        public returns (bool)
    {
        // This will throw if the requester is not previously allowed due to the protection of the ".sub" method. This
        // is the only check that the requester is actually approved to do so
        uint256 currentAllowance = getUintFromDoubleMapping(FUNDABLE_CONTRACT_NAME, _ALLOWED_TO_REQUEST_FUNDING, walletToFund, msg.sender);
        _approveToRequestFunding(walletToFund, msg.sender, currentAllowance.sub(amount));
        return _requestFunding(fundingId, walletToFund, msg.sender, amount, instructions);
    }

    function _requestFunding(string memory fundingId, address walletToFund, address requester, uint256 amount, string memory instructions)
        private returns (bool)
    {
        pushStringToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, fundingId);
        pushAddressToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, walletToFund);
        pushAddressToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, requester);
        pushUintToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, amount);
        pushStringToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, instructions);
        pushUintToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, uint256(FundingRequestStatusCode.Requested));
        emit FundingRequested(fundingId, walletToFund, requester, amount, instructions);
        return true;
    }

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
        setUintToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, index, uint256(FundingRequestStatusCode.Cancelled));
        if(walletToFund != requester) {
            _approveToRequestFunding(walletToFund, requester, allowanceToRequestFunding(walletToFund, requester).add(amount));
        }
        emit FundingRequestCancelled(fundingId, walletToFund, requester);
        return true;
    }

    function executeFundingRequest(string memory fundingId) public
        fundingRequestNotClosed(fundingId)
        onlyRole(ADMIN_ROLE)
        returns (bool)
    {
        // This to be done upstream and then call this.supra
        // _mint(_fundings[fundingId].requester, _fundings[fundingId].amount);
        uint256 index;
        address walletToFund;
        address requester;
        uint256 amount;
        string memory instructions;
        FundingRequestStatusCode status;
        (index, walletToFund, requester, amount, instructions, status) = retrieveFundingData(fundingId);
        setUintToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, index, uint256(FundingRequestStatusCode.Executed));
        emit FundingRequestExecuted(fundingId, walletToFund, requester);
        return true;
    }

    function rejectFundingRequest(string memory fundingId, string memory reason) public
        fundingRequestNotClosed(fundingId)
        onlyRole(ADMIN_ROLE)
        returns (bool)
    {
        uint256 index;
        address walletToFund;
        address requester;
        uint256 amount;
        string memory instructions;
        FundingRequestStatusCode status;
        (index, walletToFund, requester, amount, instructions, status) = retrieveFundingData(fundingId);
        setUintToArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, index, uint256(FundingRequestStatusCode.Rejected));
        if(walletToFund != requester) {
            _approveToRequestFunding(walletToFund, requester, allowanceToRequestFunding(walletToFund, requester).add(amount));
        }
        emit FundingRequestRejected(fundingId, walletToFund, requester, reason);
        return true;
    }

    function retrieveFundingData(string memory fundingId)
        public view
        returns (uint256 index, address walletToFund, address requester, uint256 amount, string memory instructions, FundingRequestStatusCode status)
    {
        index = _getIndex(fundingId);
        walletToFund = _getWalletToFund(fundingId);
        requester = _getRequester(fundingId);
        amount = _getAmount(fundingId);
        instructions = _getInstructions(fundingId);
        status = _getStatus(fundingId);
    }

    function manyFundingRequests() public view returns (uint256 many) {
        return getUintFromArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS, 0);
    }

}