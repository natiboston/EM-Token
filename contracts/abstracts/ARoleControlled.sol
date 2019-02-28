pragma solidity ^0.5;

import "../libraries/Strings.sol";

/**
 * @title RoleControlled
 * @dev The RoleControlled contract implements a generic role modifier that can be used to control role
 * based access to contract methods. It works in a similar fashion to the *Role contracts in OpenZeppelin
 * in https://github.com/OpenZeppelin/openzeppelin-solidity/tree/master/contracts/access/rolescd (e.g. MinterRole.sol),
 * but all the methods take a string parameter to denote a specific role. This way, OpenZeppelin's MinterRole's
 * OnlyMinter() modifier can be implemented as OnlyRole("minter")
 * @dev An special, predefined AdminRole role is provided. The constructor sets this admin role for the contract
 * owner, and this role cannot be renounced. So in essence, ÒnlyRole(AdminRole) is equivalent to the OnlyOwner()
 * modifier from the traditional Ownable contract.
 * @dev This has already been migrated to the EternalStorage construct, so all storage variables are used through
 * the EternalStorageWrapper
 */
contract ARoleControlled {

    using Strings for string;

    /**
     * @notice AdminRole is the predefined role with admin rights. This is the role that can grant all roles
     * (including other admins), and transfer the admin role itself
     */
    bytes32 constant internal ADMIN_ROLE = "administrator";

    bytes32 constant internal ROLECONTROLLED_CONTRACT_NAME = "RoleControlled";

    /**
     * @dev Data structures for limits and drawn amounts, to be implemented in the eternal storage:
     * @dev _ROLES :mapping (bytes32 => mapping (address => bool)) storing the repository of roles
     */
    bytes32 constant internal _ROLES = "_roles";

    event RoleAdded(address indexed account, bytes32 indexed role);
    event RoleRemoved(address indexed account, bytes32 indexed role);

    modifier onlyRole(bytes32 role) {
        require(hasRole(msg.sender, role), string("Sender does not have role ").concat(role));
        _;
    }

    /**
     * @notice Returns whether an address has a specific role
     * @param account The address being refererenced
     * @param role The role being checked
     */
    function hasRole(address account, bytes32 role) public view returns (bool);

    /**
     * @notice Gives a role to an address
     * @dev Only an address with the Admin role can add roles
     * @param account The address to which the role is going to be given
     * @param role The role being given
     */
    function addRole(address account, bytes32 role) public returns (bool);

    /**
     * @notice Allows an address to renounce a role that was given to it
     * @dev Admin roles cannot be renounced
     * @param role The role being renounced
     */
    function renounceRole(bytes32 role) public returns (bool);

    /**
     * @notice Revokes a role from a particular address
     * @dev Only an address with the Admin role can revoke roles
     * @param account The address being revoked
     * @param role The role being revoked
     */
    function revokeRole(address account, bytes32 role) public returns (bool);

    /**
     * @notice Allows a role bearer to transfer role to another account
     * @dev Only a role bearer can transfer its rolw
     * @param newAccount The address being revoked
     * @param role The role being transferred
     */
    function transferRole(address newAccount, bytes32 role) public returns (bool);

}