pragma solidity ^0.5;

import "./EternalStorage.sol";
import "./Pausable.sol";

contract EternalStorageBase is Pausable {

    EternalStorage internal _eternalStorage;

    event EternalStorageSet(address oldEternalStorage, address newEternalStorage);

    constructor () internal {
    }

    modifier externalStorageSet() {
        require(isEternalStorageSet(), "Eternal Storage not set");
        _;
    }

    function isEternalStorageSet() public view returns(bool) {
        return _eternalStorage.isContractConnected(address(this));
    }

    function whichEternalStorage() public view returns(EternalStorage) {
        return _eternalStorage;
    }

    function setEternalStorage(address newEternalStorage) onlyOwner public {
        require(newEternalStorage != address(0), "Storage address cannot be zero");
        emit EternalStorageSet(address(_eternalStorage), newEternalStorage);
        _eternalStorage = EternalStorage(newEternalStorage);
        require(isEternalStorageSet(), "Not authorized by EternalStorage");
    }

    // Indexing keys
    function singleElementKey(bytes32 module, bytes32 variableName) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(module, variableName));
    }

    function indexedElementKey(bytes32 module, bytes32 arrayName, uint256 index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(module, arrayName, index));
    }

    function indexedElementKey(bytes32 module, bytes32 arrayName, address _key) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(module, arrayName, _key));
    }

    function indexedElementKey(bytes32 module, bytes32 arrayName, string memory _key) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(module, arrayName, _key));
    }

    function doubleIndexedElementKey(bytes32 module, bytes32 arrayName, bytes32 _key1, address _key2) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(module, arrayName, _key1, _key2));
    }

    function doubleIndexedElementKey(bytes32 module, bytes32 arrayName, address _key1, address _key2) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(module, arrayName, _key1, _key2));
    }

    // Array helper
    function getNumberOfElementsInArray(bytes32 module, bytes32 array)
        public view
        externalStorageSet
        notPaused
        returns (uint256) {
        bytes32 key = singleElementKey(module, array);
        return _eternalStorage.getUint(key);
    }

    // uint256

    function getUint(bytes32 module, bytes32 variable)
        public view
        externalStorageSet
        notPaused
        returns (uint)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.getUint(key);
    }

    function setUint(bytes32 module, bytes32 variable, uint256 value)
        public
        externalStorageSet
        notPaused
        returns(bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.setUint(key, value);
    }

    function deleteUint(bytes32 module, bytes32 variable)
        public
        externalStorageSet
        notPaused
        returns(bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.deleteUint(key);
    }

    // int256

    function getInt(bytes32 module, bytes32 variable)
        public view
        externalStorageSet
        notPaused
        returns (int)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.getInt(key);
    }

    function setInt(bytes32 module, bytes32 variable, int256 value)
        public
        externalStorageSet
        notPaused
        returns(bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.setInt(key, value);
    }

    function deleteInt(bytes32 module, bytes32 variable)
        public
        externalStorageSet
        notPaused
        returns(bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.deleteInt(key);
    }

    // address

    function getAddress(bytes32 module, bytes32 variable)
        public view
        externalStorageSet
        notPaused
        returns (address)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.getAddress(key);
    }

    function setAddress(bytes32 module, bytes32 variable, address value)
        public
        externalStorageSet
        notPaused
        returns(bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.setAddress(key, value);
    }

    function deleteAddress(bytes32 module, bytes32 variable)
        public
        externalStorageSet
        notPaused
        returns(bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.deleteAddress(key);
    }

    // bytes

    function getBytes(bytes32 module, bytes32 variable)
        public view
        externalStorageSet
        notPaused
        returns (bytes memory)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.getBytes(key);
    }

    function setBytes(bytes32 module, bytes32 variable, bytes memory value)
        public
        externalStorageSet
        notPaused
        returns(bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.setBytes(key, value);
    }

    function deleteBytes(bytes32 module, bytes32 variable)
        public
        externalStorageSet
        notPaused
        returns(bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.deleteBytes(key);
    }

    // bool

    function getBool(bytes32 module, bytes32 variable)
        public view
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.getBool(key);
    }

    function setBool(bytes32 module, bytes32 variable, bool value)
        public
        externalStorageSet
        notPaused
        returns(bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.setBool(key, value);
    }

    function deleteBool(bytes32 module, bytes32 variable)
        public
        externalStorageSet
        notPaused
        returns(bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.deleteBool(key);
    }

    // string

    function getString(bytes32 module, bytes32 variable)
        public view
        externalStorageSet
        notPaused
        returns (string memory)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.getString(key);
    }

    function setString(bytes32 module, bytes32 variable, string memory value)
        public
        externalStorageSet
        notPaused
        returns(bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.setString(key, value);
    }

    function deleteString(bytes32 module, bytes32 variable)
        public
        externalStorageSet
        notPaused
        returns(bool)
    {
        bytes32 key = singleElementKey(module, variable);
        return _eternalStorage.deleteString(key);
    }

}