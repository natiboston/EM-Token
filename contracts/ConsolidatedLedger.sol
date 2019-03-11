pragma solidity ^0.5;

import "./ERC20Ledger.sol";
import "./HoldsLedger.sol";
import "./OverdraftsLedger.sol";

/**
 * @title ConsolidatedLedger
 * @dev This contract implements methods to operate balances on a consolidated fashion taking info account
 * ERC20 balances, overdrafts and holds
 */
contract ConsolidatedLedger is ERC20Ledger, HoldsLedger, OverdraftsLedger {

    // External functions

    function availableFunds(address wallet) external view returns (uint256) {
        return _availableFunds(wallet);
    }
    
    // Internal functions
    
    function _addFunds(address wallet, uint256 amount) internal {
        uint256 currentDrawnAmount = _drawnAmount(wallet);
        if(currentDrawnAmount >= amount) {
            _restoreOverdraft(wallet, amount);
        } else {
            if(currentDrawnAmount > 0) {
                _restoreOverdraft(wallet, currentDrawnAmount);
            }
            _increaseBalance(wallet, amount.sub(currentDrawnAmount));
        }
    }

    function _removeFunds(address wallet, uint256 amount) internal {
        uint256 currentBalance = _balanceOf(wallet);
        if (amount <= currentBalance) {
            _decreaseBalance(wallet, amount);
        } else {
            if(currentBalance > 0) {
                _decreaseBalance(wallet, currentBalance);
            }
            _drawFromOverdraft(wallet, amount.sub(currentBalance));
        }
    }

    function _availableFunds(address wallet) internal view returns (uint256) {
        return
            _balanceOf(wallet)
            .add(_unsecuredOverdraftLimit(wallet))
            .sub(_drawnAmount(wallet))
            .sub(_balanceOnHold(wallet));
    }

}
