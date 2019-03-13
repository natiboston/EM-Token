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

    /**
     * @notice increaseUnsecuredOverdraftLimit increases the overdraft limit for an account
     * @param account the address of the account
     * @param amount the amount to be added to the current overdraft limit
     * @dev Only the CRO is allowed to do this
     */
    function increaseUnsecuredOverdraftLimit(address account, uint256 amount) external onlyRole(CRO_ROLE) returns (bool) {
        uint256 oldLimit = _unsecuredOverdraftLimit(account);
        uint256 newLimit = oldLimit.add(amount);
        emit UnsecuredOverdraftLimitSet(account, oldLimit, newLimit);
        return _setUnsecuredOverdraftLimit(account, amount);
    }

    /**
     * @notice decreaseUnsecuredOverdraftLimit decreases the overdraft limit for an account, assuming the drawn amount is
     * not excessive (i.e. the drawn amount should be below the drawn amount)
     * @param account the address of the account
     * @param amount the amount to be substracted from the current overdraft limit
     * @dev No check is done to see if the limit will become lower than the drawn amount. Although this may result in a
     * margin call of some sort, the primary benefit of this is preventing the user from further drawing from the line
     * @dev Only the CRO is allowed to do this
     */
    function decreaseUnsecuredOverdraftLimit(address account, uint256 amount) external onlyRole(CRO_ROLE) returns (bool) {
        uint256 oldLimit = _unsecuredOverdraftLimit(account);
        uint256 newLimit = oldLimit.sub(amount);
        emit UnsecuredOverdraftLimitSet(account, oldLimit, newLimit);
        return _setUnsecuredOverdraftLimit(account, amount);
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

}