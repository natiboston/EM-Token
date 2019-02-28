pragma solidity ^0.5;

import "./EternalStorage/EternalStorageUintArray.sol";
import "./EternalStorage/EternalStorageAddressArray.sol";
import "./EternalStorage/EternalStorageStringArray.sol";
import "./EternalStorage/EternalStorageAllAddressMappings.sol";
import "./EternalStorage/EternalStorageAllStringMappings.sol";
import "./EternalStorage/EternalStorageBoolDoubleMapping.sol";
import "./EternalStorage/EternalStorageUintDoubleMapping.sol";

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
contract EternalStorageWrapper is
    EternalStorageUintArray,
    EternalStorageAddressArray,
    EternalStorageStringArray,
    EternalStorageAllAddressMappings,
    EternalStorageAllStringMappings,
    EternalStorageBoolDoubleMapping,
    EternalStorageUintDoubleMapping
{

}