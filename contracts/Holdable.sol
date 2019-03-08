pragma solidity ^0.5;

import "./Compliant.sol";

contract Holdable is Compliant {

    // Data structures (in eternal storage)
    // Events
    // Constructor
    // Modifiers
    // Interface functions
    // Internal functions
    // Private functions

    // External state-modifying functions

    function hold(
        string calldata holdId,
        address payer,
        address payee,
        address notary,
        uint256 amount,
        uint256 expiration
    )
        external
        onlyRole(HOLDER_ROLE)
        returns (uint256 index)
    {
        // _check(blah blah);
        uint256 availableFunds =
            _balanceOf(payer)
            .add(_unsecuredOverdraftLimit(payer))
            .sub(_drawnAmount(payer))
            .sub(_balanceOnHold(payer));
        require(amount >= availableFunds, "Not enough funds to hold");
        return _createHold(holdId, msg.sender, payer, payee, notary, amount, expiration);
    }
    
    // External view functions

    /**
     * @dev Function to retrieve all the information available for a particular hold
     * @param holdId The ID of the hold
     */
    function retrieveHoldData(address issuer, string calldata holdId)
        external view
        returns (
            uint256 index,
            address payer,
            address payee,
            address notary,
            uint256 amount,
            uint256 expiration,
            HoldStatusCode status
        )
    {
        return _holdData(issuer, holdId);
    }

    /**
     * @dev Function to retrieve all the information available for a particular hold
     * @param index The index of the hold
     */
    function getHoldData(uint256 index)
        external view
        returns (
            string memory holdId,
            address issuer,
            address payer,
            address payee,
            address notary,
            uint256 amount,
            uint256 expiration,
            HoldStatusCode status
        )
    {
        return _holdData(index);
    }

    /**
     * @dev This function returns the amount of funding requests outstanding and closed, since they are stored in an
     * array and the position in the array constitutes the ID of each funding request
     */
    function manyHolds() external view returns (uint256 many) {
        return _manyHolds();
    }

    /**
     * @dev Function to know how much is locked on hold from a particular wallet
     * @param account The address of the account
     */
    function balanceOnHold(address account) external view returns (uint256) {
        return _balanceOnHold(account);
    }

    /**
     * @dev Function to know how much is locked on hold for all accounts
     */
    function totalSupplyOnHold() external view returns (uint256) {
        return _totalSupplyOnHold();
    }

}

