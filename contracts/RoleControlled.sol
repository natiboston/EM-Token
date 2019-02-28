pragma solidity ^0.5;

import "../../../OpenZeppelin/openzeppelin-solidity/contracts/access/Roles.sol";
import "./abstracts/ARoleControlled.sol";
import "./EternalStorageWrapper.sol";
import "./libraries/Strings.sol";

contract RoleControlled is ARoleControlled, EternalStorageWrapper {

    using Roles for Roles.Role;
    using Strings for string;

    constructor () internal {
        _addRole(msg.sender, ADMIN_ROLE);
    }

    function hasRole(address account, bytes32 role) public view returns (bool) {
        return getBoolFromDoubleMapping(ROLECONTROLLED_CONTRACT_NAME, _ROLES, role, account);
    }

    function addRole(address account, bytes32 role) public onlyRole(ADMIN_ROLE) returns (bool) {
        require(account != address(0), "Cannot add role to address 0");
        return _addRole(account, role);
    }

    function renounceRole(bytes32 role) public returns (bool) {
        require(role != ADMIN_ROLE, "Admin role cannot be renounced");
        return _removeRole(msg.sender, role);
    }

    function revokeRole(address account, bytes32 role) public onlyRole(ADMIN_ROLE) returns (bool) {
        require(account != address(0), "Cannot revoke role from address 0");
        return _removeRole(account, role);
    }

    function transferRole(address newAccount, bytes32 role) public returns (bool) {
        require(hasRole(msg.sender, role), string("Sender does not have role ").concat(role));
        require(newAccount != address(0), "Cannot transfer role to address 0");
        _removeRole(msg.sender, role);
        return _addRole(newAccount, role);
    }

    function _addRole(address _account, bytes32 role) internal returns (bool) {
        emit RoleAdded(_account, role);
        return setBoolInDoubleMapping(ROLECONTROLLED_CONTRACT_NAME, _ROLES, role, _account, true);
    }

    function _removeRole(address account, bytes32 role) internal returns (bool) {
        emit RoleRemoved(account, role);
        return deleteBoolFromDoubleMapping(ROLECONTROLLED_CONTRACT_NAME, _ROLES, role, account);
    }

}