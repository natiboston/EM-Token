pragma solidity ^0.5;

import "../../../OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./EternalStorage.sol";

/**
 * @title EternalStorageWrapper
 * @dev The EternalStorageWrapper can be inherited by contracts that want to use the EternalStorage construct
 * @dev Elements in the storage should be referenced using a "module" and a "variable" names, plus one or several
 * indices in the case of complex types such as arrays or mappings. This way different components (e.g. different
 * contracts inherited by the same contract) can use variables with identical names. Note that only one contract
 * instance can connect to an Eternal Storage instance
 * @dev The wrapper needs to be connected to the EternalStorage instance to start operating normally. The correct
 * sequence is:
 * 1. Instantiate EternalStorage and the contract inheriting the EternalStorageWrapper
 * 2. Call the connectContract() method in EternalStorage to whitelist the wrapper)
 * 3. Call the setEternalStorage() method in EternalStorageWrapper to connect to the storage. Note that this will
 *    fail if the wrapper is not previously whitelisted
 */
 contract EternalStorageWrapper is Ownable {

    EternalStorage private _eternalStorage;

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

    function doubleIndexedElementKey(bytes32 module, bytes32 arrayName, bytes32 _key1, address _key2) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(module, arrayName, _key1, _key2));
    }

    // Example: uint256

    function getUint(bytes32 module, bytes32 uintVariable) externalStorageSet public view returns (uint) {
        bytes32 key = singleElementKey(module, uintVariable);
        return _eternalStorage.getUint(key);
    }

    function setUint(bytes32 module, bytes32 uintVariable, uint256 value) externalStorageSet public returns(bool) {
        bytes32 key = singleElementKey(module, uintVariable);
        return _eternalStorage.setUint(key, value);
    }

    function deleteUint(bytes32 module, bytes32 uintVariable)externalStorageSet  public returns(bool) {
        bytes32 key = singleElementKey(module, uintVariable);
        return _eternalStorage.deleteUint(key);
    }

    // Example: uint256 array

    function getNumberOfElementsInArray(bytes32 module, bytes32 array) externalStorageSet public view returns (uint256) {
        bytes32 key = singleElementKey(module, array);
        return _eternalStorage.getUint(key);
    }

    function pushToUintArray(bytes32 module, bytes32 uintArray, uint256 newValue) externalStorageSet public returns (bool) {
        setUint(module, uintArray, getUint(module, uintArray) + 1);
        return setUintArrayElement(module, uintArray, getNumberOfElementsInArray(module, uintArray) - 1, newValue);
    }

    function getUintArrayElement(bytes32 module, bytes32 uintArray, uint256 element) externalStorageSet public view returns (uint) {
        require(element < getNumberOfElementsInArray(module, uintArray), "Array out of bounds");
        bytes32 key = indexedElementKey(module, uintArray, element);
        return _eternalStorage.getUint(key);
    }

    function setUintArrayElement(bytes32 module, bytes32 uintArray, uint256 element, uint256 value) externalStorageSet public returns (bool) {
        require(element < getNumberOfElementsInArray(module, uintArray), "Array out of bounds");
        bytes32 key = indexedElementKey(module, uintArray, element);
        return _eternalStorage.setUint(key, value);
    }

    function deleteUintArrayElement(bytes32 module, bytes32 uintArray, uint256 element) externalStorageSet public returns (bool) {
        require(element < getNumberOfElementsInArray(module, uintArray), "Array out of bounds");
        setUintArrayElement(module, uintArray, element, getUintArrayElement(module, uintArray, getNumberOfElementsInArray(module, uintArray) - 1));
        bytes32 key = indexedElementKey(module, uintArray, getNumberOfElementsInArray(module, uintArray) - 1);
        return _eternalStorage.deleteUint(key);
    }

    // Mappings

    // Get element:
    function getUintFromMapping(bytes32 _module, bytes32 _mapping, address _key) externalStorageSet public view returns (uint) {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.getUint(key);
    }

    function getBoolFromMapping(bytes32 _module, bytes32 _mapping, address _key) externalStorageSet public view returns (bool) {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.getBool(key);
    }


    // Set element:
    function setUintInMapping(bytes32 _module, bytes32 _mapping, address _key, uint256 _value) externalStorageSet public returns (bool) {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.setUint(key, _value);
    }

    function setBoolInMapping(bytes32 _module, bytes32 _mapping, address _key, bool _value) externalStorageSet public returns (bool) {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.setBool(key, _value);
    }


    // Delete element:
    function deleteUintFromMapping(bytes32 _module, bytes32 _mapping, address _key) externalStorageSet public returns (bool) {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.deleteUint(key);
    }

    function deleteBoolFromMapping(bytes32 _module, bytes32 _mapping, address _key) externalStorageSet public returns (bool) {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.deleteBool(key);
    }

    // Double mappings

    function getBoolFromDoubleMapping(bytes32 _module, bytes32 _mapping, bytes32 _key1, address _key2) externalStorageSet public view returns (bool) {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.getBool(key);
    }

    function setBoolInDoubleMapping(bytes32 _module, bytes32 _mapping, bytes32 _key1, address _key2, bool _value) externalStorageSet public returns (bool) {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
       return _eternalStorage.setBool(key, _value);
    }

    function deleteBoolFromDoubleMapping(bytes32 _module, bytes32 _mapping, bytes32 _key1, address _key2) externalStorageSet public returns (bool) {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.deleteBool(key);
    }

}