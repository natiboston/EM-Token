pragma solidity ^0.5;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

    int256 constant private INT256_MIN = -2**255;
    int256 constant private INT256_MAX = 2**255 - 1;
    string constant MULTIPLICATION_OVERFLOW = "Overflow in multiply operation";
    string constant DIVISION_OVERFLOW = "Overflow in division operation";
    string constant ADDITION_OVERFLOW = "Overflow in addition operation";
    string constant SUBSTRACTION_OVERFLOW = "Overflow in substraction operation";
    string constant CONVERSION_OVERFLOW = "Uint cannot be converted to Int (too big)";
    
    // uint256:

    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, MULTIPLICATION_OVERFLOW);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, DIVISION_OVERFLOW); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, SUBSTRACTION_OVERFLOW);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, ADDITION_OVERFLOW);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, DIVISION_OVERFLOW);
        return a % b;
    }

    // int256

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN), MULTIPLICATION_OVERFLOW); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b, MULTIPLICATION_OVERFLOW);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, DIVISION_OVERFLOW); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN), DIVISION_OVERFLOW); // This is the only case of overflow

        int256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), SUBSTRACTION_OVERFLOW);

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), ADDITION_OVERFLOW);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(int256 a, int256 b) internal pure returns (int256) {
        require(b > 0, DIVISION_OVERFLOW);
        return a % b;
    }

    /**
     * @dev Converts an uint into an int, and throws if out of range
     */
    function toInt(uint256 a) internal pure returns (int256) {
        require(a <= uint256(INT256_MAX), CONVERSION_OVERFLOW);
        return(int256(a));
    }

}
