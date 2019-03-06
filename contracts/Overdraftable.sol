pragma solidity ^0.5;

import "./Compliant.sol";
import "./libraries/SafeMath.sol";

/**
 * @title Overdraftable - simple implementation of an overdraft line
 * @dev Overdraft lines can only be drawn or restored through internal methods, i.e. to use this through inheritance with
 * other contracts
 */
contract Overdraftable is Compliant {

    using SafeMath for uint256;

    // Data structures (in eternal storage)

    // Events

    // Constructor

    // Modifiers

    // Interface functions

    /**
     * @notice increaseUnsecuredOverdraftLimit increases the overdraft limit for an account
     * @param account the address of the account
     * @param amount the amount to be added to the current overdraft limit
     * @dev Only the CRO is allowed to do this
     */
    function increaseUnsecuredOverdraftLimit(address account, uint256 amount) onlyRole(CRO_ROLE) public returns (bool) {
        return _increaseUnsecuredOverdraftLimit(account, amount);
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
    function decreaseUnsecuredOverdraftLimit(address account, uint256 amount) onlyRole(CRO_ROLE) public returns (bool) {
        return _decreaseUnsecuredOverdraftLimit(account, amount);
    }

    // Internal functions

    // Private functions    

}