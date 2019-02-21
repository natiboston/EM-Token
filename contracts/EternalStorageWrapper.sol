pragma solidity ^0.5;

import "./RoleControlled.sol";
import "./EternalStorage.sol";

contract EternalStorageWrapper is RoleControlled {

    EternalStorage private _eternalStorage;

    event EternalStorageSet(address oldEternalStorage, address newEternalStorage);

    constructor (address eternalStorage, bytes32 version) internal {
        setEternalStorage(eternalStorage, version);
    }

    modifier externalStorageSet() {
        require(address(_eternalStorage) != address(0), "Eternal Storage not set");
        _;
    }

    function whichEternalStorage() public view returns(EternalStorage) {
        return _eternalStorage;
    }

    function setEternalStorage(address newEternalStorage, bytes32 version) onlyRole(AdminRole) public returns(bool) {
        require(newEternalStorage != address(0), "Storage address cannot be zero");
        emit EternalStorageSet(address(_eternalStorage), newEternalStorage);
        _eternalStorage = EternalStorage(newEternalStorage);
        require(_eternalStorage.version() == version, "Wrong eternal storage vesion");
        return true;
    }

    // uint256

    function getUint(bytes32 uintVariable) externalStorageSet public view returns (uint) {
        return _eternalStorage.getUint(uintVariable);
    }

    function setUint(bytes32 uintVariable, uint256 value) externalStorageSet public returns(bool) {
        return _eternalStorage.setUint(uintVariable, value);
    }

    function deleteUint(bytes32 uintVariable)externalStorageSet  public returns(bool) {
        return _eternalStorage.deleteUint(uintVariable);
    }

    function getNumberOfElementsInUintArray(bytes32 uintArray) externalStorageSet public view returns (uint256) {
        return _eternalStorage.getUint(uintArray);
    }

    function pushToUintArray(bytes32 uintArray, uint256 newValue) externalStorageSet public returns (bool) {
        setUint(uintArray, getUint(uintArray) + 1);
        return setUintArrayElement(uintArray, getNumberOfElementsInUintArray(uintArray) - 1, newValue);
    }

    function getUintArrayElement(bytes32 uintArray, uint256 element) externalStorageSet public view returns (uint) {
        require(element < getNumberOfElementsInUintArray(uintArray), "Array out of bounds");
        return _eternalStorage.getUint(keccak256(abi.encodePacked(uintArray, element)));
    }

    function setUintArrayElement(bytes32 uintArray, uint256 element, uint256 value) externalStorageSet public returns (bool) {
        require(element < getNumberOfElementsInUintArray(uintArray), "Array out of bounds");
        return _eternalStorage.setUint(keccak256(abi.encodePacked(uintArray, element)), value);
    }

    function deleteUintArrayElement(bytes32 uintArray, uint256 element) externalStorageSet public returns (bool) {
        require(element < getNumberOfElementsInUintArray(uintArray), "Array out of bounds");
        setUintArrayElement(uintArray, element, getUintArrayElement(uintArray, getNumberOfElementsInUintArray(uintArray) - 1));
        return _eternalStorage.deleteUint(keccak256(abi.encodePacked(uintArray, getNumberOfElementsInUintArray(uintArray) - 1)));
    }

    function getUintMappingElement(bytes32 uintMapping, address key) externalStorageSet public view returns (uint) {
        return _eternalStorage.getUint(keccak256(abi.encodePacked(uintMapping, key)));
    }

    function setUintMappingElement(bytes32 uintMapping, address key, uint256 value) externalStorageSet public returns (bool) {
        return _eternalStorage.setUint(keccak256(abi.encodePacked(uintMapping, key)), value);
    }

    function deleteUintMappingElement(bytes32 uintMapping, address key) externalStorageSet public returns (bool) {
        return _eternalStorage.deleteUint(keccak256(abi.encodePacked(uintMapping, key)));
    }

    // int256

    /* To do */



}