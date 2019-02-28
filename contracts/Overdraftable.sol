pragma solidity ^0.5;

import "./RoleControlled.sol";
import "./abstracts/AOverdraftable.sol";
import "./libraries/SafeMath.sol";

contract Overdraftable is AOverdraftable, RoleControlled {

    using SafeMath for uint256;

    function getUnsecuredOverdraftLimit(address account) public view returns (uint256) {
        return getUintFromMapping(OVERDRAFTABLE_CONTRACT_NAME, _UNSECURED_OVERDRAFT_LIMITS, account);
    }

    function increaseUnsecuredOverdraftLimit(address account, uint256 amount) onlyRole(CRO_ROLE) public returns (bool) {
        uint256 oldLimit = getUnsecuredOverdraftLimit(account);
        uint256 newLimit = oldLimit.add(amount);
        emit UnsecuredOverdraftLimitSet(account, oldLimit, newLimit);
        return setUintInMapping(OVERDRAFTABLE_CONTRACT_NAME, _UNSECURED_OVERDRAFT_LIMITS, account, newLimit);
    }

    function decreaseUnsecuredOverdraftLimit(address account, uint256 amount) onlyRole(CRO_ROLE) public returns (bool) {
        uint256 oldLimit = getUnsecuredOverdraftLimit(account);
        uint256 newLimit = oldLimit.sub(amount);
        require(newLimit >= getDrawnAmount(account), "Cannot set limit below drawn amount");
        emit UnsecuredOverdraftLimitSet(account, oldLimit, newLimit);
        return setUintInMapping(OVERDRAFTABLE_CONTRACT_NAME, _UNSECURED_OVERDRAFT_LIMITS, account, newLimit);
    }

    function getDrawnAmount(address account) public returns (uint256) {
        return getUintFromMapping(OVERDRAFTABLE_CONTRACT_NAME, _UNSECURED_OVERDRAFT_LIMITS, account);
    }

    // Held amounts need to be checked in order to authorize this. So the function on top will need to check (require) and
    // then call this.supra
    function drawFromOverdraft(address account, uint256 amount) internal returns (bool) {
        uint256 newAmount = getDrawnAmount(account).add(amount);
        require(getUnsecuredOverdraftLimit(account) >= newAmount, "Not enough credit limit");
        emit OverdraftChanged(account, getDrawnAmount(account), newAmount);
        return setUintInMapping(OVERDRAFTABLE_CONTRACT_NAME, _OVERDRAFTS_DRAWN, account, newAmount);
    }

    function restoreOverdraft(address account, uint256 amount) internal returns (bool) {
        uint256 newAmount = getDrawnAmount(account).sub(amount);
        emit OverdraftChanged(account, getDrawnAmount(account), newAmount);
        return setUintInMapping(OVERDRAFTABLE_CONTRACT_NAME, _OVERDRAFTS_DRAWN, account, newAmount);
    }

    function setCRO(address account) onlyRole(CRO_ROLE) public returns (bool) {
        return addRole(account, CRO_ROLE);
    }

    function revokeCRO(address account) onlyRole(CRO_ROLE) public returns (bool) {
        return revokeRole(account, CRO_ROLE);
    }

}