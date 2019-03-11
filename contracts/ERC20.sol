pragma solidity ^0.5;

import "./Compliant.sol";
import "./libraries/SafeMath.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic functions of the standard token
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20 is Compliant {

    using SafeMath for uint256;

    // Events

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // External state-modifying functions

    /**
    * @notice Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) external returns (bool) {
        _check(checkTransfer, msg.sender, to);
        return _transfer(msg.sender, to, value);
    }

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        _check(checkApprove, msg.sender, spender);
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice Method to increase approval
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function increaseApproval(address spender, uint256 value) external returns (bool) {
        _check(checkApprove, msg.sender, spender);
        _approve(msg.sender, spender, _allowance(msg.sender, spender).add(value));
        return true;
    }

    /**
     * @notice Method to decrease approval
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function decreaseApproval(address spender, uint256 value) external returns (bool) {
        _check(checkApprove, msg.sender, spender);
        _approve(msg.sender, spender, _allowance(msg.sender, spender).sub(value));
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        _check(checkTransfer, from, to);
        _approve(from, msg.sender, _allowance(from, msg.sender).sub(value));
        return _transfer(msg.sender, to, value);
    }

    // External view functions

    /**
    * @notice Total number of tokens in existence
    */
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }

    /**
    * @notice Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) external view returns (uint256) {
        return _balanceOf(owner);
    }

    /**
     * @notice Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance(owner, spender);
    }

    // Internal functions

    function _transfer(address from, address to, uint256 value) internal returns (bool) {
        _removeFunds(from, value);
        _addFunds(to, value);
        emit Transfer(from, to, value);
        return true;
    }

}
