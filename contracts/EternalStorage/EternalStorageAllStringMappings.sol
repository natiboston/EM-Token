pragma solidity ^0.5;

import "./EternalStorageBase.sol";

contract EternalStorageAllStringMappings is EternalStorageBase {

    // Get element:
    function getUintFromMapping(bytes32 _module, bytes32 _mapping, string memory _key)
        public view
        externalStorageSet
        notPaused
        returns (uint)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.getUint(key);
    }

    function getIntFromMapping(bytes32 _module, bytes32 _mapping, string memory _key)
        public view
        externalStorageSet
        notPaused
        returns (int)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.getInt(key);
    }

    function getAddressFromMapping(bytes32 _module, bytes32 _mapping, string memory _key)
        public view
        externalStorageSet
        notPaused
        returns (address)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.getAddress(key);
    }

    function getBytesFromMapping(bytes32 _module, bytes32 _mapping, string memory _key)
        public view
        externalStorageSet
        notPaused
        returns (bytes memory)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.getBytes(key);
    }

    function getBoolFromMapping(bytes32 _module, bytes32 _mapping, string memory _key)
        public view
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.getBool(key);
    }

    function getStringFromMapping(bytes32 _module, bytes32 _mapping, string memory _key)
        public view
        externalStorageSet
        notPaused
        returns (string memory)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.getString(key);
    }


    // Set element:
    function setUintInMapping(bytes32 _module, bytes32 _mapping, string memory _key, uint256 _value)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.setUint(key, _value);
    }

    function setIntInMapping(bytes32 _module, bytes32 _mapping, string memory _key, int256 _value)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.setInt(key, _value);
    }

    function setAddressInMapping(bytes32 _module, bytes32 _mapping, string memory _key, address _value)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.setAddress(key, _value);
    }

    function setBytesInMapping(bytes32 _module, bytes32 _mapping, string memory _key, bytes memory _value)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.setBytes(key, _value);
    }

    function setBoolInMapping(bytes32 _module, bytes32 _mapping, string memory _key, bool _value)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.setBool(key, _value);
    }

    function setStringInMapping(bytes32 _module, bytes32 _mapping, string memory _key, string memory _value)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.setString(key, _value);
    }


    // Delete element:
    function deleteUintFromMapping(bytes32 _module, bytes32 _mapping, string memory _key)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.deleteUint(key);
    }

    function deleteIntFromMapping(bytes32 _module, bytes32 _mapping, string memory _key)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.deleteInt(key);
    }

    function deleteAddressFromMapping(bytes32 _module, bytes32 _mapping, string memory _key)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.deleteAddress(key);
    }

    function deleteBoolFromMapping(bytes32 _module, bytes32 _mapping, string memory _key)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.deleteBool(key);
    }

    function deleteStringFromMapping(bytes32 _module, bytes32 _mapping, string memory _key)
        public
        externalStorageSet
        notPaused
        returns (bool)
    {
        bytes32 key = indexedElementKey(_module, _mapping, _key);
        return _eternalStorage.deleteString(key);
    }

}
