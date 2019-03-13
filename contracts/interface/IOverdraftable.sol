pragma solidity ^0.5;

interface IOverdraftable {

    event UnsecuredOverdraftLimitSet(address indexed account, uint256 oldLimit, uint256 newLimit);

    /**
     * @notice increaseUnsecuredOverdraftLimit increases the overdraft limit for an account
     * @param account the address of the account
     * @param amount the amount to be added to the current overdraft limit
     * @dev Only the CRO is allowed to do this
     */
    function increaseUnsecuredOverdraftLimit(address account, uint256 amount) external returns (bool);

    /**
     * @notice decreaseUnsecuredOverdraftLimit decreases the overdraft limit for an account, assuming the drawn amount is
     * not excessive (i.e. the drawn amount should be below the drawn amount)
     * @param account the address of the account
     * @param amount the amount to be substracted from the current overdraft limit
     * @dev No check is done to see if the limit will become lower than the drawn amount. Although this may result in a
     * margin call of some sort, the primary benefit of this is preventing the user from further drawing from the line
     * @dev Only the CRO is allowed to do this
     */
    function decreaseUnsecuredOverdraftLimit(address account, uint256 amount) external returns (bool);

    // External view functions
    
    /**
     * @notice unsecuredOverdraftLimit returns the unsecured overdraft limit for an account
     * @param account the address of the account
     * @return The limit of the overdraft line
     */
    function unsecuredOverdraftLimit(address account) external view returns (uint256);

    /**
     * @notice drawnAmount returns the amount drawn from the overdraft line
     * @param account the address of the account
     * @return The amount already drawn from the overdraft line
     */
    function drawnAmount(address account) external view returns (uint256);

}