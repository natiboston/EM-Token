pragma solidity ^0.5;

library StringConverter {
    function toHash(string memory _s) internal pure returns (bytes32) {
        return keccak256(abi.encode(_s));
    }
}
