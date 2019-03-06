pragma solidity ^0.5;

import "./EternalStorageWrapper.sol";
import "./libraries/SafeMath.sol";

contract HoldsLedger is EternalStorageWrapper {

    using SafeMath for uint256;

    // Data structures (in eternal storage)

    enum HoldStatusCode { Nonexistent, Created, Executed, ReleasedByNotary, ReleasedByPayee, ReleasedByOwner, ReleasedDueToExpiration }

    bytes32 constant private HOLDSLEDGER_CONTRACT_NAME = "HoldsLedger";

    /**
     * @dev Data structures (implemented in the eternal storage):
     * @dev _HOLD_IDS : string array with hold IDs
     * @dev _HOLD_ISSUERS : address array with the issuers of the holds ("holders")
     * @dev _HOLD_PAYERS : address array with the payers of the holds
     * @dev _HOLD_PAYEES : address array with the payees of the holds
     * @dev _HOLD_NOTARIES : address array with the notaries of the holds
     * @dev _HOLD_AMOUNTS : uint256 array with the amounts of the holds
     * @dev _HOLD_EXPIRATIONS : uint256 array with the expirations of the holds
     * @dev _HOLD_STATUS_CODES : uint256 array with the status codes of the holds
     * @dev _HOLD_IDS_INDEXES : mapping (string => uint256) with the indexes for hold data
     * @dev _BALANCES_ON_HOLD : mapping (address => uint256) with the total amounts on hold for each wallet
     * @dev _TOTAL_SUPPLY_ON_HOLD : Uint with the total amount on hold in the system
     */
    bytes32 constant private _HOLD_IDS = "_holdIds";
    bytes32 constant private _HOLD_ISSUERS = "_holdIssuers";
    bytes32 constant private _HOLD_PAYERS = "_holdPayers";
    bytes32 constant private _HOLD_PAYEES = "_holdPayees";
    bytes32 constant private _HOLD_NOTARIES = "_holdNotaries";
    bytes32 constant private _HOLD_AMOUNTS = "_holdAmounts";
    bytes32 constant private _HOLD_EXPIRATIONS = "_holdExpirations";
    bytes32 constant private _HOLD_STATUS_CODES = "_holdStatusCodes";
    bytes32 constant private _HOLD_IDS_INDEXES = "_holdIDsIndexes";
    bytes32 constant private _BALANCES_ON_HOLD = "_balancesOnHold";
    bytes32 constant private _TOTAL_SUPPLY_ON_HOLD = "_totalSupplyOnHold";

    // Events

    event HoldCreated(
        string indexed holdId,
        address issuer,
        address indexed payer,
        address payee,
        address indexed notary,
        uint256 amount,
        uint256 expiration,
        uint256 index
    ); // By issuer (which can be the payer as well)

    event HoldExecuted(string indexed holdId); // By notary

    event HoldReleased(string indexed holdId, HoldStatusCode status); // By issuer, by notary, by payee, or due to expiration

    event HoldRenewed(string indexed holdId, uint256 oldExpiration, uint256 newExpiration); // By issuer

    // Constructor

    // Modifiers

    modifier holdExists(string memory holdId) {
        require (_getHoldIndex(holdId) > 0, "Hold does not exist");
        _;
    }

    modifier holdIndexExists(uint256 index) {
        require (index > 0 && index <= manyHolds(), "Hold does not exist");
        _;
    }

    modifier holdDoesNotExist(string memory holdId) {
        require (_getHoldIndex(holdId) == 0, "Hold exists");
        _;
    }

    // Interface functions

    /**
     * @dev Function to retrieve all the information available for a particular hold
     * @param holdId The ID of the hold
     */
    function retrieveHoldData(string memory holdId)
        public view
        returns (
            uint256 index,
            address issuer,
            address payer,
            address payee,
            address notary,
            uint256 amount,
            uint256 expiration,
            HoldStatusCode status
        )
    {
        index = _getHoldIndex(holdId);
        issuer = _getHoldIssuer(index);
        payer = _getHoldPayer(index);
        payee = _getHoldPayee(index);
        notary = _getHoldPayee(index);
        amount = _getHoldAmount(index);
        expiration = _getHoldExpiration(index);
        status = _getHoldStatus(index);
    }

    /**
     * @dev Function to retrieve all the information available for a particular hold
     * @param index The index of the hold
     */
    function retrieveHoldData(uint256 index)
        public view
        returns (
            string memory holdId,
            address issuer,
            address payer,
            address payee,
            address notary,
            uint256 amount,
            uint256 expiration,
            HoldStatusCode status
        )
    {
        holdId = _getHoldID(index);
        issuer = _getHoldIssuer(index);
        payer = _getHoldPayer(index);
        payee = _getHoldPayee(index);
        notary = _getHoldPayee(index);
        amount = _getHoldAmount(index);
        expiration = _getHoldExpiration(index);
        status = _getHoldStatus(index);
    }

    /**
     * @dev This function returns the amount of funding requests outstanding and closed, since they are stored in an
     * array and the position in the array constitutes the ID of each funding request
     */
    function manyHolds() public view returns (uint256 many) {
        return getUintFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_IDS, 0);
    }

    /**
     * @dev Function to know how much is locked on hold from a particular wallet
     * @param account The address of the account
     */
    function balanceOnHold(address account) public view returns (uint256) {
        return _getBalanceOnHold(account);
    }

    /**
     * @dev Function to know how much is locked on hold for all accounts
     */
    function totalSupplyOnHold() public view returns (uint256) {
        return _getTotalSupplyOnHold();
    }

    // Internal functions

    function _createHold(
        string memory holdId,
        address issuer,
        address payer,
        address payee,
        address notary,
        uint256 amount,
        uint256 expiration
    )
        internal
        returns (uint256 index)
    {
        index = _pushNewHold(holdId, issuer, payer, payee, notary, amount, expiration);
        _addBalanceOnHold(payer, amount);
        emit HoldCreated(holdId, issuer, payer, payee, notary, amount, expiration, index);
    }

    function _finalizeHold(string memory holdId, HoldStatusCode status) internal returns (bool) {
        require(_getHoldStatus(_getHoldIndex(holdId)) == HoldStatusCode.Created, "Hold status should be 'created'");
        if(status == HoldStatusCode.Executed)
            emit HoldExecuted(holdId);
        else
            emit HoldReleased(holdId, status);
        address payer = _getHoldPayer(_getHoldIndex(holdId));
        uint256 amount = _getHoldAmount(_getHoldIndex(holdId));
        bool r1 = _substractBalanceOnHold(payer, amount);
        bool r2 = _setHoldStatus(_getHoldIndex(holdId), status);
        return r1 && r2;
    }

    // Private functions

    function _getHoldIndex(string memory holdId) private view holdExists(holdId) returns (uint256) {
        return getUintFromMapping(HOLDSLEDGER_CONTRACT_NAME, _HOLD_IDS_INDEXES, holdId);
    }

    function _getHoldID(uint256 index) private view holdIndexExists(index) returns (string memory) {
        return getStringFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_IDS, index);
    }

    function _getHoldIssuer(uint256 index) private view holdIndexExists(index) returns (address) {
        return getAddressFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_ISSUERS, index);
    }

    function _getHoldPayer(uint256 index) private view holdIndexExists(index) returns (address) {
        return getAddressFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_PAYERS, index);
    }

    function _getHoldPayee(uint256 index) private view holdIndexExists(index) returns (address) {
        return getAddressFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_PAYEES, index);
    }

    function _getHoldNotary(uint256 index) private view holdIndexExists(index) returns (address) {
        return getAddressFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_NOTARIES, index);
    }

    function _getHoldAmount(uint256 index) private view holdIndexExists(index) returns (uint256) {
        return getUintFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_AMOUNTS, index);
    }

    function _getHoldExpiration(uint256 index) private view holdIndexExists(index) returns (uint256) {
        return getUintFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_EXPIRATIONS, index);
    }

    function _getHoldStatus(uint256 index) private view holdIndexExists(index) returns (HoldStatusCode) {
        return HoldStatusCode(getUintFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_STATUS_CODES, index));
    }

    function _setHoldStatus(uint256 index, HoldStatusCode status) private holdIndexExists(index) returns (bool) {
        return setUintInArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_STATUS_CODES, index, uint256(status));
    }

    function _getBalanceOnHold(address account) private view returns (uint256) {
        return getUintFromMapping(HOLDSLEDGER_CONTRACT_NAME, _BALANCES_ON_HOLD, account);
    }

    function _getTotalSupplyOnHold() private view returns (uint256) {
        return getUint(HOLDSLEDGER_CONTRACT_NAME, _TOTAL_SUPPLY_ON_HOLD);
    }

    function _addBalanceOnHold(address account, uint256 amount) private returns (bool) {
        bool r1 = setUintInMapping(HOLDSLEDGER_CONTRACT_NAME, _BALANCES_ON_HOLD, account, _getBalanceOnHold(account).add(amount));
        bool r2 = setUint(HOLDSLEDGER_CONTRACT_NAME, _TOTAL_SUPPLY_ON_HOLD, _getTotalSupplyOnHold().add(amount));
        return r1 && r2;
    }

    function _substractBalanceOnHold(address account, uint256 amount) private returns (bool) {
        bool r1 = setUintInMapping(HOLDSLEDGER_CONTRACT_NAME, _BALANCES_ON_HOLD, account, _getBalanceOnHold(account).sub(amount));
        bool r2 = setUint(HOLDSLEDGER_CONTRACT_NAME, _TOTAL_SUPPLY_ON_HOLD, _getTotalSupplyOnHold().sub(amount));
        return r1 && r2;
    }

    function _pushNewHold(
        string memory holdId,
        address issuer,
        address payer,
        address payee,
        address notary,
        uint256 amount,
        uint256 expiration
    )
        internal
        holdDoesNotExist(holdId)
        returns (uint256)
    {
        pushStringToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_IDS, holdId);
        pushAddressToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_ISSUERS, issuer);
        pushAddressToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_PAYERS, payer);
        pushAddressToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_PAYEES, payee);
        pushAddressToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_NOTARIES, notary);
        pushUintToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_AMOUNTS, amount);
        pushUintToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_EXPIRATIONS, expiration);
        uint256 index = manyHolds();
        setUintInMapping(HOLDSLEDGER_CONTRACT_NAME, _HOLD_IDS_INDEXES, holdId, index);
        return index;
    }

}
