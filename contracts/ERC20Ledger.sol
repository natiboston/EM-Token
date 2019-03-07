pragma solidity ^0.5;

import "./EternalStorageWrapper.sol";
import "./libraries/SafeMath.sol";

/**
 * @title ERC20Ledger - basic ledger functions and data
 *
 * @dev This contract implements the core elements of the ERC20 ledger:
 * - Private data (all core data is private, not internal)
 * - Internal functions that annotate this data
 * - Public view functions (callable by users for consultation purposes)
 * @dev This contract is intended to be used from a higher order ERC20 token implementation (i.e.
 * inherting from this one)
 *
 */
contract ERC20Ledger is EternalStorageWrapper {

    using SafeMath for uint256;

    // Data structures (in eternal storage)

    bytes32 constant private ERC20LEDGER_CONTRACT_NAME = "ERC20Ledger";

    /**
     * @dev Data structures
     * @dev _BALANCES : address to uint mapping to store balances
     * @dev _ALLOWED : address to address to uint mapping to store allowances 
     * @dev _TOTALSUPPLY : uint storing total supply
     */
    bytes32 constant private _BALANCES = "_balances";
    bytes32 constant private _ALLOWED = "_allowed";
    bytes32 constant private _TOTALSUPPLY = "_totalSupply";

    // Events
    
    event BalanceIncrease(address indexed account, uint256 value);
    event BalanceDecrease(address indexed account, uint256 value);

    // Constructor

    // Modifiers

    modifier notAddressZero(address who) {
        require(who != address(0), "Address 0 is reserved");
        _;
    }

    // Internal functions

    function _approve(address allower, address spender, uint256 value) internal notAddressZero(spender) returns (bool) {
        return _setAllowance(allower, spender, value);
    }

    function _increaseAllowance(address allower, address spender, uint256 addedValue) internal notAddressZero(spender) returns (bool) {
        uint256 newAllowance = _getAllowance(allower, spender).add(addedValue);
        return _setAllowance(allower, spender, newAllowance);
    }

    function _decreaseAllowance(address allower, address spender, uint256 subtractedValue) internal notAddressZero(spender) returns (bool) {
        uint256 newAllowance = _getAllowance(allower, spender).sub(subtractedValue);
        return _setAllowance(allower, spender, newAllowance);
    }

    function _increaseBalance(address account, uint256 value) internal returns (bool) {
        uint256 newBalance = _getBalance(account).add(value);
        uint256 newTotalSupply = _getTotalSupply().add(value);
        bool r1 = _setBalance(account, newBalance);
        bool r2 = _setTotalSupply(newTotalSupply);
        emit BalanceIncrease(account, value);
        return r1 && r2;
    }

    function _decreaseBalance(address account, uint256 value) internal returns (bool) {
        uint256 newBalance = _getBalance(account).sub(value);
        uint256 newTotalSupply = _getTotalSupply().sub(value);
        bool r1 = _setBalance(account, newBalance);
        bool r2 = _setTotalSupply(newTotalSupply);
        emit BalanceDecrease(account, value);
        return r1 && r2;
    }

    function _totalSupply() internal view returns (uint256) {
        return _getTotalSupply();
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        return _getBalance(owner);
    }

    function _allowance(address owner, address spender) internal view returns (uint256) {
        return _getAllowance(owner, spender);
    }

    // Private functions

    function _getBalance(address owner) private view returns (uint256) {
        return getUintFromMapping(ERC20LEDGER_CONTRACT_NAME, _BALANCES, owner);
    }

    function _setBalance(address owner, uint256 value) private returns (bool) {
        return setUintInMapping(ERC20LEDGER_CONTRACT_NAME, _BALANCES, owner, value);
    }

    function _getAllowance(address owner, address spender) private view returns (uint256) {
        return getUintFromDoubleMapping(ERC20LEDGER_CONTRACT_NAME, _ALLOWED, owner, spender);
    }

    function _setAllowance(address owner, address spender, uint256 value) private returns (bool) {
        return setUintInDoubleMapping(ERC20LEDGER_CONTRACT_NAME, _ALLOWED, owner, spender, value);
    }

    function _getTotalSupply() private view returns (uint256) {
        return getUint(ERC20LEDGER_CONTRACT_NAME, _TOTALSUPPLY);
    }

    function _setTotalSupply(uint256 value) private returns (bool) {
        return setUint(ERC20LEDGER_CONTRACT_NAME, _TOTALSUPPLY, value);
    }

}
