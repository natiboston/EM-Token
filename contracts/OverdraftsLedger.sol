pragma solidity ^0.5;

import "./EternalStorageWrapper.sol";
import "./libraries/SafeMath.sol";

/**
 * @title OverdraftsLedger
 *
 * @dev This contract implements the core elements of the ledger to support overdraft lines
 * - Private data (all core data is private, not internal)
 * - Internal functions that annotate this data
 * - Public view functions (callable by users for consultation purposes)
 * @dev This contract is intended to be used from a higher order ERC20 token implementation (i.e.
 * inherting from this one)
 */
contract OverdraftsLedger is EternalStorageWrapper {

    using SafeMath for uint256;

    // Data structures (in eternal storage)

    bytes32 constant private OVERDRAFTSLEDGER_CONTRACT_NAME = "OverdraftsLedger";

    /**
     * @dev Data structures for limits and drawn amounts, to be implemented in the eternal storage:
     * @dev _UNSECURED_OVERDRAFT_LIMITS : mapping (address => uint256) storing the overdraft limits (unsecured)
     * @dev _OVERDRAFTS_DRAWN : mapping (address => uint256) storing the drawn overdraft limits
     * @dev _TOTAL_OVERDRAFT_DRAWN : uint256 with the total amounts drawn in overdraft (analogous to totalSupply in ERC20)
     */
    bytes32 constant private _UNSECURED_OVERDRAFT_LIMITS = "_unsecuredOverdraftsLimits";
    bytes32 constant private _DRAWN_AMOUNTS = "_drawnAmounts";
    bytes32 constant private _TOTAL_DRAWN_AMOUNTS = "_totalDrawnAmounts";

    // Events

    event OverdraftDrawn(address indexed account, uint256 amount);
    event OverdraftRestored(address indexed account, uint256 amount);

    // Internal functions

    function _unsecuredOverdraftLimit(address account) internal view returns (uint256) {
        return _getUnsecuredOverdraftLimit(account);
    }

    function _drawnAmount(address account) internal view returns (uint256) {
        return _getDrawnAmount(account);
    }

    function _setUnsecuredOverdraftLimit(address account, uint256 newLimit) internal returns (bool) {
        return _writeUnsecuredOverdraftLimit(account, newLimit);
    }

    function _drawFromOverdraft(address account, uint256 amount) internal returns (bool) {
        uint256 newAmount = _getDrawnAmount(account).add(amount);
        uint256 newTotalAmount = _getTotalDrawnAmount().add(amount);
        emit OverdraftDrawn(account, amount);
        return _setDrawnAmounts(account, newAmount) && _setTotalDrawnAmount(newTotalAmount);
    }

    function _restoreOverdraft(address account, uint256 amount) internal returns (bool) {
        uint256 newAmount = _getDrawnAmount(account).sub(amount);
        uint256 newTotalAmount = _getTotalDrawnAmount().sub(amount);
        emit OverdraftRestored(account, amount);
        return _setDrawnAmounts(account, newAmount) && _setTotalDrawnAmount(newTotalAmount);
    }

    function _totalDrawnAmount() internal view returns (uint256) {
        return _getTotalDrawnAmount();
    }

    // Private functions

    function _getUnsecuredOverdraftLimit(address account) private view returns (uint256) {
        return getUintFromMapping(OVERDRAFTSLEDGER_CONTRACT_NAME, _UNSECURED_OVERDRAFT_LIMITS, account);
    }

    function _writeUnsecuredOverdraftLimit(address account, uint256 value) private returns (bool) {
        return setUintInMapping(OVERDRAFTSLEDGER_CONTRACT_NAME, _UNSECURED_OVERDRAFT_LIMITS, account, value);
    }

    function _getDrawnAmount(address account) private view returns (uint256) {
        return getUintFromMapping(OVERDRAFTSLEDGER_CONTRACT_NAME, _DRAWN_AMOUNTS, account);
    }

    function _setDrawnAmounts(address account, uint256 value) private returns (bool) {
        return setUintInMapping(OVERDRAFTSLEDGER_CONTRACT_NAME, _DRAWN_AMOUNTS, account, value);
    }

    function _getTotalDrawnAmount() private view returns (uint256) {
        return getUint(OVERDRAFTSLEDGER_CONTRACT_NAME, _DRAWN_AMOUNTS);
    }

    function _setTotalDrawnAmount(uint256 value) private returns (bool) {
        return setUint(OVERDRAFTSLEDGER_CONTRACT_NAME, _DRAWN_AMOUNTS, value);
    }

}
