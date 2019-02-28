pragma solidity ^0.5;

import "../../../../OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract Pausable is Ownable {

    bool private _paused;

    event Paused();
    event Restarted();

    /**
    * @dev Manager can call this function to pause all user-callable functions
    */
    function pause() onlyOwner external {
        _paused = true;
        emit Paused();
    }

    /**
    * @dev Manager can call this function to re-enable all user-callable functions
    */
    function restart() onlyOwner external {
        _paused = false;
        emit Restarted();
    }

    /**
    * @dev Returns whether contract is paused or not
    */
    function isPaused() external view returns (bool) {
        return _paused;
    }

    /**
    * @dev Modifier for user functions
    */
    modifier notPaused() {
        require (!_paused, "Contract is paused");
        _;
    }

}