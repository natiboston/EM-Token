pragma solidity ^0.5;

interface IConsolidatedLedger {

    /**
     * @dev Returns the total net funds available in a wallet, taking into account the outright balance, the
     * drawn overdrafts, the available overdraft limit, and the holds taken
     */
    function availableFunds(address wallet) external view returns (uint256);

    /**
     * @dev Returns the net balance in a wallet, calculated as balance minus overdraft drawn amount
     * @dev (note that this could have been calculated as balance > 0 ? balance : - drawn amount)
     */
    function netBalanceOf(address wallet) external view returns (int256);
    
}