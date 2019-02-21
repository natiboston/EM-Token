pragma solidity ^0.5;

import "../../../OpenZeppelin/openzeppelin-solidity/contracts/access/Roles.sol";
import "./libraries/StringConverter.sol";

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
 */
contract RoleControlled {

    using Roles for Roles.Role;
    using StringConverter for string;

    /**
     * @notice AdminRole is the predefined role with admin rights. This is the role that can grant all roles
     * (including other admins), and transfer the admin role itself
     */
    string constant public AdminRole = "administrator";

    event RoleAdded(address indexed account, string indexed role);
    event RoleRemoved(address indexed account, string indexed role);

    mapping (bytes32 => Roles.Role) private _roles;

    constructor () internal {
        _addRole(msg.sender, AdminRole);
    }

    modifier onlyRole(string memory role) {
        require(hasRole(msg.sender, role), string(abi.encodePacked("Sender does not have role ", role)));
        _;
    }

    function hasRole(address account, string memory role) public view returns (bool) {
        return _roles[role.toHash()].has(account);
    }

    function addRole(address account, string memory role) public onlyRole(AdminRole) {
        require(account != address(0), "Cannot add role to address 0");
        _addRole(account, role);
    }

    function renounceRole(string memory role) public {
        require(role.toHash() != AdminRole.toHash(), "Admin role cannot be renounced");
        _removeRole(msg.sender, role);
    }

    function revokeRole(address account, string memory role) public onlyRole(AdminRole) {
        require(account != address(0), "Cannot revoke role from address 0");
        _removeRole(account, role);
    }

    function transferRole(address newAccount, string memory role) public {
        require(hasRole(msg.sender, role), string(abi.encodePacked("Sender does not have role ", role)));
        require(newAccount != address(0), "Cannot transfer role to address 0");
        _removeRole(msg.sender, role);
        _addRole(newAccount, role);
    }

    function _addRole(address account, string memory role) internal {
        _roles[role.toHash()].add(account);
        emit RoleAdded(account, role);
    }

    function _removeRole(address account, string memory role) internal {
        _roles[role.toHash()].remove(account);
        emit RoleRemoved(account, role);
    }

}