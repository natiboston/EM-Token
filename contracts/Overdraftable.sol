pragma solidity ^0.5;

import "./Compliant.sol";
import "./interface/IOverdraftable.sol";
import "./libraries/SafeMath.sol";

/**
 * @title Overdraftable - simple implementation of an overdraft line
 * @dev Overdraft lines can only be drawn or restored through internal methods, which are implemented in HoldsLedger.
 * This contract is only valid to set limits and read drawn amounts
 */
contract Overdraftable is IOverdraftable, Compliant {

    using SafeMath for uint256;

    // External functions

    /**
     * @notice increaseUnsecuredOverdraftLimit increases the overdraft limit for an account
     * @param account the address of the account
     * @param newLimit the amount to be added to the current overdraft limit
     * @dev Only the CRO is allowed to do this
     * @dev As of yet, this is not part of the standard EM Token specification
     */
    function setUnsecuredOverdraftLimit(address account, uint256 newLimit) external onlyRole(CRO_ROLE) returns (bool) {
        uint256 oldLimit = _unsecuredOverdraftLimit(account);
        emit UnsecuredOverdraftLimitSet(account, oldLimit, newLimit);
        return _setUnsecuredOverdraftLimit(account, newLimit);
    }

    // External view functions
    
    /**
     * @notice unsecuredOverdraftLimit returns the unsecured overdraft limit for an account
     * @param account the address of the account
     * @return The limit of the overdraft line
     */
    function unsecuredOverdraftLimit(address account) external view returns (uint256) {
        return _unsecuredOverdraftLimit(account);
    }

    /**
     * @notice drawnAmount returns the amount drawn from the overdraft line
     * @param account the address of the account
     * @return The amount already drawn from the overdraft line
     */
    function drawnAmount(address account) external view returns (uint256) {
        return _drawnAmount(account);
    }

    /**
     * @notice totalDrawnAmount returns the addition of all the amounts drawn from overdraft lines in all wallets
     * @return The total amount drawn from all overdraft lines
     */
    function totalDrawnAmount() external view returns (uint256) {
        return _totalDrawnAmount();
    }

}