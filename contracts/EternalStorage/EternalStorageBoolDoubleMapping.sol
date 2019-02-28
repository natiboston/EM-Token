pragma solidity ^0.5;

import "./EternalStorageBase.sol";

contract EternalStorageBoolDoubleMapping is EternalStorageBase {

    // Get element:
    function getBoolFromDoubleMapping(bytes32 _module, bytes32 _mapping, bytes32 _key1, address _key2)
        public view
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.getBool(key);
    }

    function getBoolFromDoubleMapping(bytes32 _module, bytes32 _mapping, address _key1, address _key2)
        public view
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.getBool(key);
    }

    // Set element:

    function setBoolInDoubleMapping(bytes32 _module, bytes32 _mapping, bytes32 _key1, address _key2, bool _value)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.setBool(key, _value);
    }

    function setBoolInDoubleMapping(bytes32 _module, bytes32 _mapping, address _key1, address _key2, bool _value)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.setBool(key, _value);
    }

    // Delete element

    function deleteBoolFromDoubleMapping(bytes32 _module, bytes32 _mapping, bytes32 _key1, address _key2)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.deleteBool(key);
    }

    function deleteBoolFromDoubleMapping(bytes32 _module, bytes32 _mapping, address _key1, address _key2)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = doubleIndexedElementKey(_module, _mapping, _key1, _key2);
        return _eternalStorage.deleteBool(key);
    }

}
