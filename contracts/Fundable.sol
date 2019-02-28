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
    
    function _getIndex(string memory fundingId) private view fundingRequestExists(fundingId) returns (uint256) {
        return getUintFromMapping(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS_INDICES, fundingId);
    }

    function _getwalletToFund(string memory fundingId) private view returns (address) {
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

    modifier fundingRequestExists(string memory fundingId) {
        require(
            (getNumberOfElementsInArray(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS) > 0) &&
            (getUintFromMapping(FUNDABLE_CONTRACT_NAME, _FUNDING_IDS_INDICES, fundingId) >0),
            "Funding request does not exist"
        );
        _;
    }

    modifier fundingRequestNotClosed(string memory fundingId) {
        require(_getStatus(fundingId) == FundingRequestStatusCode.Requested, "Funding request is already closed");
        _;
    }

    modifier fundingRequesterOnly(string memory fundingId) {
        require(msg.sender == _getRequester(fundingId), "Sender is not the requester");
        _;
    }

    // Now to the actual implementation:

    function approveToRequestFunding(address requester, uint256 amount) external returns (bool) {
        setUintInDoubleMapping(FUNDABLE_CONTRACT_NAME, _ALLOWED_TO_REQUEST_FUNDING, msg.sender, requester, amount);
        emit ApprovalToRequestFunding(msg.sender, requester, amount);
        return true;
    }

/*
    function allowanceToRequestFunding(address walletToFund, address requester) external view returns (uint256) {
        return _allowedToRequestFunding[walletToFund][requester];
    }

    function requestFunding(uint256 amount, string calldata instructions) external
        notPaused
        returns (uint256 fundingId) {

        return _requestFunding(msg.sender, msg.sender, amount, instructions);
    }

    function requestFundingFrom(address walletToFund, uint256 amount, string calldata instructions) external
        notPaused
        returns (uint256 fundingId) {

        // This will throw if the requester is not previously allowed due to the protection of the ".sub" method. This
        // is the only check that the requester is actually approved to do so
        _approveToRequestFunding(walletToFund, msg.sender, _allowedToRequestFunding[walletToFund][msg.sender].sub(amount));
        return _requestFunding(walletToFund, msg.sender, amount, instructions);
    }

    function _requestFunding(address walletToFund, address requester, uint256 amount, string memory instructions) internal
    returns (uint256 fundingId) {

        fundingId = _fundings.push(FundingRequestData(walletToFund, requester, amount, instructions, FundingRequestStatusCode.Requested)) - 1;
        emit FundingRequested(fundingId, walletToFund, msg.sender, amount, instructions);
        return fundingId;
    }

    function cancelFundingRequest(uint256 fundingId) external
        fundingRequestExists(fundingId)
        fundingRequestNotClosed(fundingId)
        fundingRequesterOnly(fundingId)
        notPaused
        returns (bool) {

        _fundings[fundingId].status = FundingRequestStatusCode.Cancelled;
        if(_fundings[fundingId].walletToFund != _fundings[fundingId].requester && msg.sender == _fundings[fundingId].requester) {
            _approveToRequestFunding(_fundings[fundingId].walletToFund, _fundings[fundingId].requester, _allowedToRequestFunding[_fundings[fundingId].walletToFund][_fundings[fundingId].requester].add(_fundings[fundingId].amount));
        }
        emit FundingRequestCancelled(fundingId, _fundings[fundingId].walletToFund, _fundings[fundingId].requester);
        return true;
    }

    function executeFundingRequest(uint256 fundingId) external
        fundingRequestExists(fundingId)
        fundingRequestNotClosed(fundingId)
        onlyOwner
        returns (bool) {

        // This to be done upstream and then call this.supra
        // _mint(_fundings[fundingId].requester, _fundings[fundingId].amount);
        _fundings[fundingId].status = FundingRequestStatusCode.Executed;
        emit FundingRequestExecuted(fundingId, _fundings[fundingId].walletToFund, _fundings[fundingId].requester);
        return true;
    }

    function rejectFundingRequest(uint256 fundingId, string calldata reason) external
        fundingRequestExists(fundingId)
        fundingRequestNotClosed(fundingId)
        onlyOwner
        returns (bool) {

        if(_fundings[fundingId].walletToFund != _fundings[fundingId].requester) {
            _approveToRequestFunding(_fundings[fundingId].walletToFund, _fundings[fundingId].requester, _allowedToRequestFunding[_fundings[fundingId].walletToFund][_fundings[fundingId].requester].add(_fundings[fundingId].amount));
        }
        _fundings[fundingId].status = FundingRequestStatusCode.Rejected;
        emit FundingRequestRejected(fundingId, _fundings[fundingId].walletToFund, _fundings[fundingId].requester, reason);
        return true;
    }

    function retrieveFundingData(uint256 fundingId) external view
        fundingRequestExists(fundingId)
        returns (address walletToFund, address requester, uint256 amount, string memory instructions, FundingRequestStatusCode status) {

        (walletToFund, requester, amount, instructions, status) = (_fundings[fundingId].walletToFund, _fundings[fundingId].requester, _fundings[fundingId].amount, _fundings[fundingId].instructions, _fundings[fundingId].status);
        return (walletToFund, requester, amount, instructions, status);
    }

    function manyFundingRequests() external view returns (uint256 many) {
        return _fundings.length;
    }
*/

}