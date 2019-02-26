pragma solidity ^0.5;

import "../../../OpenZeppelin/openzeppelin-solidity/contracts/access/Roles.sol";
import "./EternalStorageWrapper.sol";
import "./libraries/Strings.sol";

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
contract RoleControlled is EternalStorageWrapper {

    using Roles for Roles.Role;
    using Strings for string;

    /**
     * @notice AdminRole is the predefined role with admin rights. This is the role that can grant all roles
     * (including other admins), and transfer the admin role itself
     */
    bytes32 constant public ADMIN_ROLE = "administrator";

    /**
     * @notice _ROLES is the repository of roles, which is stored in the eternal storage. It is a 
     * mapping (bytes32 => mapping (address => bool)) - i.e. _roles[_role][bearer] determines if role is
     * granted or not
     */
    bytes32 constant private CONTRACT_NAME = "RoleControlled";
    bytes32 constant private _ROLES = "_roles";

    event RoleAdded(address indexed account, bytes32 indexed role);
    event RoleRemoved(address indexed account, bytes32 indexed role);

    // mapping (bytes32 => Roles.Role) private _roles;  => in eternal storage

    constructor () internal {
        _addRole(msg.sender, ADMIN_ROLE);
    }

    modifier onlyRole(bytes32 _role) {
        require(hasRole(msg.sender, _role), string("Sender does not have role ").concat(_role));
        _;
    }

    /**
     * @notice Returns whether an address has a specific role
     * @param _account The address being refererenced
     * @param _role The role being checked
     */
    function hasRole(address _account, bytes32 _role) public view returns (bool) {
        return getBoolFromDoubleMapping(CONTRACT_NAME, _ROLES, _role, _account);
    }

    /**
     * @notice Gives a role to an address
     * @dev Only an address with the Admin role can add roles
     * @param _account The address to which the role is going to be given
     * @param _role The role being given
     */
    function addRole(address _account, bytes32 _role) public onlyRole(ADMIN_ROLE) {
        require(_account != address(0), "Cannot add role to address 0");
        _addRole(_account, _role);
    }

    /**
     * @notice Allows an address to renounce a role that was given to it
     * @dev Admin roles cannot be renounced
     * @param _role The role being renounced
     */
    function renounceRole(bytes32 _role) public {
        require(_role != ADMIN_ROLE, "Admin role cannot be renounced");
        _removeRole(msg.sender, _role);
    }

    /**
     * @notice Revokes a role from a particular address
     * @dev Only an address with the Admin role can revoke roles
     * @param _account The address being revoked
     * @param _role The role being revoked
     */
    function revokeRole(address _account, bytes32 _role) public onlyRole(ADMIN_ROLE) {
        require(_account != address(0), "Cannot revoke role from address 0");
        _removeRole(_account, _role);
    }

    function transferRole(address _newAccount, bytes32 _role) public {
        require(hasRole(msg.sender, _role), string("Sender does not have role ").concat(_role));
        require(_newAccount != address(0), "Cannot transfer role to address 0");
        _removeRole(msg.sender, _role);
        _addRole(_newAccount, _role);
    }

    function _addRole(address _account, bytes32 _role) internal {
        setBoolInDoubleMapping(CONTRACT_NAME, _ROLES, _role, _account, true);
        emit RoleAdded(_account, _role);
    }

    function _removeRole(address _account, bytes32 _role) internal {
        deleteBoolFromDoubleMapping(CONTRACT_NAME, _ROLES, _role, _account);
        emit RoleRemoved(_account, _role);
    }

}