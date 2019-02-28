pragma solidity ^0.5;

/**
 * @title Overdraftable - simple implementation of an overdraft line
 * @dev Overdraft lines can only be drawn or restored through internal methods, i.e. to use this through inheritance with
 * other contracts
 */
contract AOverdraftable {

    /**
     * @notice CRORole is the predefined role with rights to change credit limits.
     */
    bytes32 constant internal CRO_ROLE = "cro";

    bytes32 constant internal OVERDRAFTABLE_CONTRACT_NAME = "Overdraftable";

    /**
     * @dev Data structures for limits and drawn amounts, to be implemented in the eternal storage:
     * @dev _UNSECURED_OVERDRAFT_LIMITS : mapping (address => uint256) storing the overdraft limits (unsecured)
     * @dev _OVERDRAFTS_DRAWN : mapping (address => uint256) storing the drawn overdraft limits
     */
    bytes32 constant internal _UNSECURED_OVERDRAFT_LIMITS = "_unsecuredOverdraftsLimits";
    bytes32 constant internal _OVERDRAFTS_DRAWN = "_overdraftsDrawn";

    event UnsecuredOverdraftLimitSet(address indexed account, uint256 oldLimit, uint256 newLimit);
    event SecuredOverdraftLimitSet(address indexed account, uint256 oldLimit, uint256 newLimit);
    event OverdraftChanged(address indexed account, uint256 oldAmount, uint256 newAmount);

    /**
     * @notice getUnsecuredOverdraftLimit returns the unsecured overdraft limit for an account
     * @param account the address of the account
     */
    function getUnsecuredOverdraftLimit(address account) public view returns (uint256);

    /**
     * @notice increaseUnsecuredOverdraftLimit increases the overdraft limit for an account
     * @param account the address of the account
     * @param amount the amount to be added to the current overdraft limit
     * @dev Only the CRO is allowed to do this
     */
    function increaseUnsecuredOverdraftLimit(address account, uint256 amount) public returns (bool); // onlyRole(CRO_ROLE)

    /**
     * @notice decreaseUnsecuredOverdraftLimit decreases the overdraft limit for an account, assuming the drawn amount is
     * not excessive (i.e. the drawn amount should be below the drawn amount)
     * @param account the address of the account
     * @param amount the amount to be substracted from the current overdraft limit
     * @dev Only the CRO is allowed to do this
     * @dev No check is done to see if the limit will become lower than the drawn amount. Although this would result in a
     * margin call of some sort, at least this will prevent to user from further drawing from the line
     */
    function decreaseUnsecuredOverdraftLimit(address account, uint256 amount) public returns (bool); // onlyRole(CRO_ROLE)

    /**
     * @notice getDrawnAmount returns the amount drawn from the overdraft line
     * @param account the address of the account
     */
    function getDrawnAmount(address account) public returns (uint256);

    /**
     * @notice drawFromOverdraft draws funds from the overdraft line
     * @param account the address of the account
     * @param amount The additional amount to be drawn from the line
     * @dev This is implemented as an internal method to be used upstream with transfer, hold, etc. (and hence is not
     * permissioned here)
     */
    function drawFromOverdraft(address account, uint256 amount) internal returns (bool);

    /**
     * @notice restoreOverdraft decreases the drawn amount from the overdraft line
     * @param account the address of the account
     * @param amount The additional amount to be restored to the line
     * @dev This is implemented as an internal method to be used upstream with transfer, hold, etc. (and hence is not
     * permissioned here)
     */
    function restoreOverdraft(address account, uint256 amount) internal returns (bool);

    /**
     * @notice setCRO grants CRO privileges to an address
     * @param account the address of the new CRO
     * @dev Only an AdminRole is allowed to do this
     */
    function setCRO(address account) public returns (bool); // onlyRole(ADMIN_ROLE)

    /**
     * @notice revokeCRO removes CRO privileges from an address
     * @param account the address of the CRO being revoked
     * @dev Only an AdminRole is allowed to do this
     */
    function revokeCRO(address account) public returns (bool); // onlyRole(ADMIN_ROLE)

}