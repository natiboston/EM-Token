pragma solidity ^0.5;

import "./Overdraftable.sol";
import "./Fundable.sol";
import "./libraries/SafeMath.sol";

contract EMoneyToken is Overdraftable, Fundable {

    using SafeMath for uint256;

    // Setting up compliance
    
    // Holding

    // Cleared transfers

    // Basic ERC20

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    // Admin

}