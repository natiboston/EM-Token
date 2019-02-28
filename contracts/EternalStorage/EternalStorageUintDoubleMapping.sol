pragma solidity ^0.5;

import "./EternalStorageBase.sol";

contract EternalStorageUintDoubleMapping is EternalStorageBase {

    // Get element:
    function getUintFromDoubleMapping(bytes32 _module, bytes32 _mapping, bytes32 _key1, address _key2)
        public view
        externalStorageSet
        notPaused
        returns (uint256)
    {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.getUint(key);
    }

    function getUintFromDoubleMapping(bytes32 _module, bytes32 _mapping, address _key1, address _key2)
        public view
        externalStorageSet
        notPaused
        returns (uint256)
    {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.getUint(key);
    }

    // Set element:

    function setUintInDoubleMapping(bytes32 _module, bytes32 _mapping, bytes32 _key1, address _key2, uint256 _value)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.setUint(key, _value);
    }

    function setUintInDoubleMapping(bytes32 _module, bytes32 _mapping, address _key1, address _key2, uint256 _value)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.setUint(key, _value);
    }

    // Delete element

    function deleteUintFromDoubleMapping(bytes32 _module, bytes32 _mapping, bytes32 _key1, address _key2)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.deleteUint(key);
    }

    function deleteUintFromDoubleMapping(bytes32 _module, bytes32 _mapping, address _key1, address _key2)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.deleteUint(key);
    }

}
