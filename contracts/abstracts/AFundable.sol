pragma solidity ^0.5;

/**
 * @title Fundable
 *
 * @notice Fundable provides ERC20 token contracts with a workflow to request and honor funding requests from external
 * bank accounts. Funding requests are issued by wallet owners (or delegated to other requesters with a "requestFrom"
 * type of method), and requests are executed or rejected by the tokenizing entity (i.e. called by the "Owner" of the
 * overall contract)
 */
contract AFundable {

    enum FundingRequestStatusCode { Requested, Executed, Rejected, Cancelled }

    event FundingRequested(string indexed fundingId, address indexed walletToFund, address indexed requester, uint256 amount, string instructions);
    event FundingRequestExecuted(string indexed fundingId, address indexed walletToFund, address indexed requester);
    event FundingRequestRejected(string indexed fundingId, address indexed walletToFund, address indexed requester, string reason);
    event FundingRequestCancelled(string indexed fundingId, address indexed walletToFund, address indexed requester);
    event ApprovalToRequestFunding(address indexed walletToFund, address indexed requester, uint256 value);

    // Allowing requesting funding on behalf of others:

    /**
     * @dev Method to approve other address to request funding on behalf of a wallet owner (analogous to "approve" in
     * ERC20 transfers)
     * @param requester The address that will be requesting funding on behalf of the wallet owner
     * @param amount The amount of the allowance
     * @notice (TO DO: add increase / decrease alloance approval methods)
     */
    function approveToRequestFunding(address requester, uint256 amount) external returns (bool);

    /**
     * @dev View method to read existing allowances to request funding
     * @param walletToFund The owner of the wallet that would receive the funding
     * @param requester The address that can request funding on behalf of the wallet owner
     */
    function allowanceToRequestFunding(address walletToFund, address requester) external view returns (uint256);

    // Initiating funding requests:

    /**
     * @dev Method for a wallet owner to request funding from the tokenizer on his/her own behalf
     * @param amount The amount requested
     * @param instructions The instructions for the funding request - e.g. routing information about the bank
     * account to be debited (normally a hash / reference to the actual information in an external repository),
     * or a code to indicate that the tokenization entity should use the default bank account associated with
     * the wallet
     */
    function requestFunding(uint256 amount, string calldata instructions) external returns (uint256 fundingId);

    /**
     * @dev Method to request funding on behalf of a (different) wallet owner (analogous to "transferFrom" in
     * classical ERC20). An allowance to request funding on behalf of the wallet owner needs to be previously approved
     * @param walletToFund The address of the wallet which will receive the funding
     * @param amount The amount requested
     * @param instructions The debit instructions, as is "requestFunding"
     */
    function requestFundingFrom(address walletToFund, uint256 amount, string calldata instructions) external returns (uint256 fundingId);

    // Cancelling funding requests:

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
    function cancelFundingRequest(uint256 fundingId) external returns (bool);

    // Executing and rejecting funding requests (to be called by the tokenizer authority, i.e. onlyOwner):

    /**
     * @dev Function to be called by the tokenizer administrator to honor a funding request. After debiting the
     * corresponding bank account, the administrator calls this method to close the request (as "Executed") and
     * mint the requested tokens into the relevant wallet
     * @param fundingId The ID of the request, which contains all the relevant information such as the amount
     * requested and the address of the wallet that receives the tokens
     * @dev Only operator can do this
     * 
     */
    function executeFundingRequest(uint256 fundingId) external returns (bool);

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
    function rejectFundingRequest(uint256 fundingId, string calldata reason) external returns (bool);

    // Looking up funding request data:

    /**
     * @dev Function to retrieve all the information available for a particular funding request
     * @param fundingId The ID of the funding request
     */
    function retrieveFundingData(uint256 fundingId) external view returns (address walletToFund, address requester, uint256 amount, string memory instructions, FundingRequestStatusCode status);

    /**
     * @dev This function returns the amount of funding requests outstanding and closed, since they are stored in an
     * array and the position in the array constitutes the ID of each funding request
     */
    function manyFundingRequests() external view returns (uint256 many);

}