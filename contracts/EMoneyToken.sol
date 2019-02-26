pragma solidity ^0.5;

import "./RoleControlled.sol";
import "./libraries/SafeMath.sol";

contract EMoneyToken is RoleControlled {

    using SafeMath for uint256;

    // Setting up credit

    /**
     * @notice CRORole is the predefined role with rights to change credit limits.
     */
    bytes32 constant public CRO_ROLE = "cro";
    bytes32 constant public UNSECURED_OVERDRAFT_LIMITS = "_unsecuredOverdraftsLimits";
    bytes32 constant public SECURED_OVERDRAFT_LIMITS = "_securedOverdraftsLimits";
    bytes32 constant public OVERDRAFTS_LIMITS_DRAWN = "_overdraftsLimitsDrawn";

    mapping (address => uint256) private _unsecuredOverdraftsLimits;
    mapping (address => uint256) private _securedOverdraftsLimits;
    mapping (address => uint256) private _overdraftsLimitsDrawn;

    // Setting up compliance
    
    // Funding and Redeeming

    // Holding

    // Basic ERC20

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    // Admin

}