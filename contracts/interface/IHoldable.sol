pragma solidity ^0.5;

interface IHoldable {

    enum HoldStatusCode {
        Nonexistent,
        Created,
        ExecutedByNotary,
        ExecutedByOperator,
        ReleasedByNotary,
        ReleasedByOperator,
        ReleasedDueToExpiration
    }

    event HoldCreated(
        address issuer,
        string  indexed transactionId,
        address indexed payer,
        address payee,
        address indexed notary,
        uint256 amount,
        bool    expires,
        uint256 expiration,
        uint256 index
    ); // By issuer (which can be the payer as well)

    event HoldExecuted(address issuer, string indexed transactionId, HoldStatusCode status); // By notary or by operator

    event HoldReleased(address issuer, string indexed transactionId, HoldStatusCode status); // By issuer), by notary, or due to expiration

    event HoldRenewed(address issuer, string indexed transactionId, uint256 oldExpiration, uint256 newExpiration); // By issuer

    /**
     * @notice Function to perform a hold on behalf of a wallet owner (the sender) in favor of another wallet owner (the
     * "payee"), and specifying a notary who will be responsable to either execute or release the transfer
     * @param transactionId An unique ID to identify the hold. Internally IDs will be stored together with the addresses
     * issuing the holds (on a mapping (address => mapping (string => XXX ))), so the same transactionId can be used by many
     * different holders. This is provided assuming that the hold functionality is a competitive resource
     * @param payee The address to which the tokens are to be paid (if the hold is executed)
     * @param notary The address of the notary who is going to determine whether the hold is to be executed or released
     * @param amount The amount to be transferred
     * @param expires A flag specifying whether the hold can expire or not
     * @param timeToExpiration (only relevant when expires==true) The time to be added to the currrent block.timestamp to
     * establish the expiration time for the hold. After the expiration time anyone can actually trigger the release of the hold
     * @return The index in the array where the hold is actually created and stored (this is an unique identifier
     * throughout the whole contract)
     */
    function hold(
        string  calldata transactionId,
        address payee,
        address notary,
        uint256 amount,
        bool    expires,
        uint256 timeToExpiration
    )
        external
        returns (uint256 index);

    /**
     * @notice Function to perform a hold on behalf of a wallet owner (the "payer") in favor of another wallet owner (the
     * "payee"), and specifying a notary who will be responsable to either execute or release the transfer
     * @param transactionId An unique ID to identify the hold. Internally IDs will be stored together with the addresses
     * issuing the holds (on a mapping (address => mapping (string => XXX ))), so the same transactionId can be used by many
     * different holders. This is provided assuming that the hold functionality is a competitive resource
     * @param payer The address from which the tokens are to be taken (if the hold is executed)
     * @param payee The address to which the tokens are to be paid (if the hold is executed)
     * @param notary The address of the notary who is going to determine whether the hold is to be executed or released
     * @param amount The amount to be transferred
     * @param expires A flag specifying whether the hold can expire or not
     * @param timeToExpiration (only relevant when expires==true) The time to be added to the currrent block.timestamp to
     * establish the expiration time for the hold. After the expiration time anyone can actually trigger the release of the hold
     * @return The index in the array where the hold is actually created and stored (this is an unique identifier
     * throughout the whole contract)
     */
    function holdFrom(
        string  calldata transactionId,
        address payer,
        address payee,
        address notary,
        uint256 amount,
        bool    expires,
        uint256 timeToExpiration
    )
        external
        returns (uint256 index);

    /**
     * @notice This function allows wallet owners to approve other addresses to perform holds on their behalf
     * @dev It is similar to the "approve" method in ERC20, but in this case no allowance is given and this is treated
     * as a "yes or no" flag
     * @param holder The address to be approved as potential issuer of holds
     */
    function approveToHold(address holder) external returns (bool);

    /**
     * @notice This function allows wallet owners to revoke holding privileges from previously approved addresses
     * @param holder The address to be revoked as potential issuer of holds
     */
    function revokeApprovalToHold(address holder) external returns (bool);

    /**
     * @notice Function to release a hold (if at all possible)
     * @param issuer The address of the original sender of the hold
     * @param transactionId The ID of the hold in question
     * @dev issuer and transactionId are needed to index a hold. This is provided so different issuers can use the same transactionId,
     * as holding is a competitive resource
     */
    function releaseHold(address issuer, string calldata transactionId) external returns (bool);
    
    /**
     * @notice Function to execute a hold (if at all possible)
     * @param issuer The address of the original sender of the hold
     * @param transactionId The ID of the hold in question
     * @dev issuer and transactionId are needed to index a hold. This is provided so different issuers can use the same transactionId,
     * as holding is a competitive resource
     * @dev Holds that are expired can still be executed by the notary or the operator (as well as released by anyone)
     */
    function executeHold(address issuer, string calldata transactionId) external returns (bool);

    /**
     * @notice Returns whether an address is approved to submit holds on behalf of other wallets
     * @param wallet The wallet on which the holds would be performed (i.e. the "payer")
     * @param holder The address approved to hold on behalf of the wallet owner
     * @return Whether the holder is approved or not to hold on behalf of the wallet owner
     */
    function isApprovedToHold(address wallet, address holder) external view returns (bool);

    /**
     * @notice Function to retrieve all the information available for a particular hold
     * @param issuer The address of the original sender of the hold
     * @param transactionId The ID of the hold in question
     * @return index: the index of the hold (an unique identifier)
     * @return payer: the wallet from which the tokens will be taken if the hold is executed
     * @return payee: the wallet to which the tokens will be transferred if the hold is executed
     * @return notary: the address that will be executing or releasing the hold
     * @return amount: the amount that will be transferred
     * @return expires: a flag indicating whether the hold expires or not
     * @return expiration: (only relevant in case expires==true) the absolute time (block.timestamp) by which the hold will
     * expire (after that time the hold can be released by anyone)
     * @return status: the current status of the hold
     * @dev issuer and transactionId are needed to index a hold. This is provided so different issuers can use the same transactionId,
     * as holding is a competitive resource
     */
    function retrieveHoldData(address issuer, string calldata transactionId)
        external view
        returns (
            uint256 index,
            address payer,
            address payee,
            address notary,
            uint256 amount,
            bool    expires,
            uint256 expiration,
            HoldStatusCode status
        );

    /**
     * @dev Function to know how much is locked on hold from a particular wallet
     * @param account The address of the account
     * @return The balance on hold for a particular account
     */
    function balanceOnHold(address account) external view returns (uint256);

    /**
     * @dev Function to know how much is locked on hold for all accounts
     * @return The total amount in balances on hold from all wallets
     */
    function totalSupplyOnHold() external view returns (uint256);
    
}