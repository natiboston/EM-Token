pragma solidity ^0.5;

import "./EternalStorageWrapper.sol";
import "./libraries/SafeMath.sol";

contract HoldsLedger is EternalStorageWrapper {

    using SafeMath for uint256;

    // Data structures (in eternal storage)

    bytes32 constant private HOLDSLEDGER_CONTRACT_NAME = "HoldsLedger";

    /**
     * @dev Data structures (implemented in the eternal storage):
     * @dev _HOLD_IDS : string array with hold IDs
     * @dev _HOLD_ISSUERS : address array with the issuers of the holds ("holders")
     * @dev _HOLD_PAYERS : address array with the payers of the holds
     * @dev _HOLD_PAYEES : address array with the payees of the holds
     * @dev _HOLD_NOTARIES : address array with the notaries of the holds
     * @dev _HOLD_AMOUNTS : uint256 array with the amounts of the holds
     * @dev _HOLD_EXPIRES : bool array with the flags that mark whether holds expire or not
     * @dev _HOLD_EXPIRATIONS : uint256 array with the expirations of the holds
     * @dev _HOLD_STATUS_CODES : uint256 array with the status codes of the holds
     * @dev _HOLD_IDS_INDEXES : mapping (address => string => uint256) with the indexes for hold data
     * (this is to allow equal IDs to be used by different requesters)
     * @dev _BALANCES_ON_HOLD : mapping (address => uint256) with the total amounts on hold for each wallet
     * @dev _TOTAL_SUPPLY_ON_HOLD : Uint with the total amount on hold in the system
     */
    bytes32 constant private _HOLD_IDS =             "_holdIds";
    bytes32 constant private _HOLD_ISSUERS =         "_holdIssuers";
    bytes32 constant private _HOLD_PAYERS =          "_holdPayers";
    bytes32 constant private _HOLD_PAYEES =          "_holdPayees";
    bytes32 constant private _HOLD_NOTARIES =        "_holdNotaries";
    bytes32 constant private _HOLD_AMOUNTS =         "_holdAmounts";
    bytes32 constant private _HOLD_EXPIRES =         "_holdExpires";
    bytes32 constant private _HOLD_EXPIRATIONS =     "_holdExpirations";
    bytes32 constant private _HOLD_STATUS_CODES =    "_holdStatusCodes";
    bytes32 constant private _HOLD_IDS_INDEXES =     "_holdIdsIndexes";
    bytes32 constant private _BALANCES_ON_HOLD =     "_balancesOnHold";
    bytes32 constant private _TOTAL_SUPPLY_ON_HOLD = "_totalSupplyOnHold";

    // Modifiers

    modifier holdIndexExists(uint256 index) {
        require (index > 0 && index <= _manyHolds(), "Hold does not exist");
        _;
    }

    modifier holdExists(address issuer, string memory transactionId) {
        require (_getHoldIndex(issuer, transactionId) > 0, "Hold does not exist");
        _;
    }

    modifier holdDoesNotExist(address issuer, string memory transactionId) {
        require (_getHoldIndex(issuer, transactionId) == 0, "Hold exists");
        _;
    }

    modifier holdWithStatus(address issuer, string memory transactionId, uint256 status) {
        require (_getHoldStatus(_getHoldIndex(issuer, transactionId)) == status, "Hold with the wrong status");
        _;
    }

    // Internal functions

    function _createHold(
        address issuer,
        string  memory transactionId,
        address payer,
        address payee,
        address notary,
        uint256 amount,
        bool    expires,
        uint256 expiration,
        uint256 status
    )
        internal
        returns (uint256 index)
    {
        index = _pushNewHold(issuer, transactionId, payer, payee, notary, amount, expires, expiration, status);
        _addBalanceOnHold(payer, amount);
    }

    function _finalizeHold(address issuer, string memory transactionId, uint256 status) internal returns (bool) {
        uint256 index = _getHoldIndex(issuer, transactionId);
        address payer = _getHoldPayer(index);
        uint256 amount = _getHoldAmount(index);
        bool r1 = _substractBalanceOnHold(payer, amount);
        bool r2 = _setHoldStatus(index, status);
        return r1 && r2;
    }

    function _holdData(address issuer, string memory transactionId)
        internal view
        returns (
            uint256 index,
            address payer,
            address payee,
            address notary,
            uint256 amount,
            bool    expires,
            uint256 expiration,
            uint256 status
        )
    {
        index = _getHoldIndex(issuer, transactionId);
        payer = _getHoldPayer(index);
        payee = _getHoldPayee(index);
        notary = _getHoldNotary(index);
        amount = _getHoldAmount(index);
        expires = _getHoldExpires(index);
        expiration = _getHoldExpiration(index);
        status = _getHoldStatus(index);
    }

    function _holdIndex(address issuer, string memory transactionId) internal view returns(uint index) {
        return _getHoldIndex(issuer, transactionId);
    }

    function _holdPayer(address issuer, string memory transactionId) internal view returns(address payer) {
        return _getHoldPayer(_getHoldIndex(issuer, transactionId));
    }

    function _holdPayee(address issuer, string memory transactionId) internal view returns(address payee) {
        return _getHoldPayee(_getHoldIndex(issuer, transactionId));
    }

    function _holdNotary(address issuer, string memory transactionId) internal view returns(address notary) {
        return _getHoldNotary(_getHoldIndex(issuer, transactionId));
    }

    function _holdAmount(address issuer, string memory transactionId) internal view returns(uint256 amount) {
        return _getHoldAmount(_getHoldIndex(issuer, transactionId));
    }

    function _holdExpires(address issuer, string memory transactionId) internal view returns(bool expires) {
        return _getHoldExpires(_getHoldIndex(issuer, transactionId));
    }

    function _holdExpiration(address issuer, string memory transactionId) internal view returns(uint256 expiration) {
        return _getHoldExpiration(_getHoldIndex(issuer, transactionId));
    }

    function _holdStatus(address issuer, string memory transactionId) internal view returns (uint256 status) {
        return _getHoldStatus(_getHoldIndex(issuer, transactionId));
    }

    function _manyHolds() internal view returns (uint256 many) {
        return _getManyHolds();
    }

    function _balanceOnHold(address account) internal view returns (uint256) {
        return _getBalanceOnHold(account);
    }

    function _totalSupplyOnHold() internal view returns (uint256) {
        return _getTotalSupplyOnHold();
    }

    function _getHoldId(uint256 index) internal view returns (address issuer, string memory transactionId) {
        return (_getHoldIssuer(index), _getTransactionId(index));
    }

    function _changeTimeToHold(address issuer, string memory transactionId, uint256 timeToExpirationFromNow) internal returns (bool) {
        return _setHoldExpiration(_getHoldIndex(issuer, transactionId), block.timestamp.add(timeToExpirationFromNow));
    }

    // Private functions

    function _getManyHolds() private view returns (uint256 many) {
        return getUintFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_IDS, 0);
    }

    function _getHoldIndex(address issuer, string memory transactionId) private view holdExists(issuer, transactionId) returns (uint256) {
        return getUintFromMapping(HOLDSLEDGER_CONTRACT_NAME, _HOLD_IDS_INDEXES, transactionId);
    }

    function _getTransactionId(uint256 index) private view holdIndexExists(index) returns (string memory) {
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

    function _getHoldExpires(uint256 index) private view holdIndexExists(index) returns (bool) {
        return getBoolFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_EXPIRES, index);
    }

    function _getHoldExpiration(uint256 index) private view holdIndexExists(index) returns (uint256) {
        return getUintFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_EXPIRATIONS, index);
    }

    function _setHoldExpiration(uint256 index, uint256 expiration) private holdIndexExists(index) returns (bool) {
        return setUintInArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_EXPIRATIONS, index, expiration);
    }

    function _getHoldStatus(uint256 index) private view holdIndexExists(index) returns (uint256) {
        return getUintFromArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_STATUS_CODES, index);
    }

    function _setHoldStatus(uint256 index, uint256 status) private holdIndexExists(index) returns (bool) {
        return setUintInArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_STATUS_CODES, index, status);
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
        address issuer,
        string  memory transactionId,
        address payer,
        address payee,
        address notary,
        uint256 amount,
        bool    expires,
        uint256 expiration,
        uint256 status
    )
        internal
        holdDoesNotExist(issuer, transactionId)
        returns (uint256)
    {
        pushStringToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_IDS, transactionId);
        pushAddressToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_ISSUERS, issuer);
        pushAddressToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_PAYERS, payer);
        pushAddressToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_PAYEES, payee);
        pushAddressToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_NOTARIES, notary);
        pushUintToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_AMOUNTS, amount);
        pushUintToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_EXPIRATIONS, expiration);
        pushBoolToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_EXPIRES, expires);
        pushUintToArray(HOLDSLEDGER_CONTRACT_NAME, _HOLD_STATUS_CODES, status);
        uint256 index = _getManyHolds();
        setUintInDoubleMapping(HOLDSLEDGER_CONTRACT_NAME, _HOLD_IDS_INDEXES, issuer, transactionId, index);
        return index;
    }

}
