pragma solidity ^0.5;

import "../../../OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title EternalStorage
 * @dev The EternalStorage contract can be used to keep all the storage needed for contracts, which would
 * then access it (to set and read) by reference. This way, contracts can stay storage-less, and therefore
 * can be easily updated (migrated) without affecting the storage.
 * @dev Contracts that will be using this EternalStorage repository need to be whitelisted ("connected")
 * in order to be able to write the storage. Only the owner can whitelist ("connect") and unwhitelist
 * ("disconnect") individual contracts.
 */
contract EternalStorage is Ownable {

    mapping (address => bool) private _connectedContracts;

    event ContractConnected(address whichContract);
    event ContractDisconnected(address whichContract);

    mapping(bytes32 => uint256) private _uIntStorage;
    mapping(bytes32 => int256) private _intStorage;
    mapping(bytes32 => address) private _addressStorage;
    mapping(bytes32 => bytes) private _bytesStorage;
    mapping(bytes32 => bool) private _boolStorage;
    mapping(bytes32 => string) private _stringStorage;

    constructor() public {
    }

    /**
     * @dev Throws if called by any account other than the _userContract.
     */
    modifier onlyConnectedContract() {
        require(_connectedContracts[msg.sender], "Calling contract not connected");
        _;
    }

    /**
     * @notice Returns whether a particular contract is whitelisted ("connected") to be able to
     * write the eternal storage
     * @param whichContract The address of the contract that is connected or not
     */
    function isContractConnected(address whichContract) public view returns (bool) {
        return _connectedContracts[whichContract];
    }

    /**
     * @notice Whitlists ("connects") a contract to be able to write the eternal storage
     * @dev Only the owner can connect a contract to the eternal storage
     * @param whichContract The address of the contract that gets connected
     */
    function connectContract(address whichContract) external onlyOwner returns (bool) {
        _connectedContracts[whichContract] = true;
        emit ContractConnected(whichContract);
        return true;
    }

    /**
     * @notice Unwhitlists ("disconnects") a contract so it will no longer be able to
     * write the eternal storage
     * @dev Only the owner can disconnect a contract from the eternal storage
     * @param whichContract The address of the contract that gets disconnected
     */
    function disconnectContract(address whichContract) external onlyOwner returns (bool) {
        _connectedContracts[whichContract] = false;
        emit ContractDisconnected(whichContract);
        return true;
    }

    // uint256

    /**
     * @notice Reads the value of a uint256 corresponding to a key
     * @param _key The key that indexes the value
     */
    function getUint(bytes32 _key) external view returns(uint256) {
        return _uIntStorage[_key];
    }

    /**
     * @notice Sets the value of a uint256 corresponding to a key
     * @param _key The key that indexes the value
     */
    function setUint(bytes32 _key, uint _value) onlyConnectedContract external returns (bool) {
        _uIntStorage[_key] = _value;
        return true;
    }

    /**
     * @notice Deletes the value of a uint256 corresponding to a key
     * @param _key The key that indexes the value
     */
    function deleteUint(bytes32 _key) onlyConnectedContract external returns (bool) {
        delete _uIntStorage[_key];
        return true;
    }

    // int256

    /**
     * @notice Reads the value of a int256 corresponding to a key
     * @param _key The key that indexes the value
     */
    function getInt(bytes32 _key) external view returns(int256) {
        return _intStorage[_key];
    }

    /**
     * @notice Sets the value of a int256 corresponding to a key
     * @param _key The key that indexes the value
     */
    function setInt(bytes32 _key, int256 _value) onlyConnectedContract external returns (bool) {
        _intStorage[_key] = _value;
        return true;
    }

    /**
     * @notice Deletes the value of a int256 corresponding to a key
     * @param _key The key that indexes the value
     */
    function deleteInt(bytes32 _key) onlyConnectedContract external returns (bool) {
        delete _intStorage[_key];
        return true;
    }

    // address

    /**
     * @notice Reads the value of an address corresponding to a key
     * @param _key The key that indexes the value
     */
    function getAddress(bytes32 _key) external view returns(address) {
        return _addressStorage[_key];
    }

    /**
     * @notice Sets the value of an address corresponding to a key
     * @param _key The key that indexes the value
     */
    function setAddress(bytes32 _key, address _value) onlyConnectedContract external returns (bool) {
        _addressStorage[_key] = _value;
        return true;
    }

    /**
     * @notice Deletes the value of an address corresponding to a key
     * @param _key The key that indexes the value
     */
    function deleteAddress(bytes32 _key) onlyConnectedContract external returns (bool) {
        delete _addressStorage[_key];
        return true;
    }

    // bytes

    /**
     * @notice Reads the value of a bytes32 corresponding to a key
     * @param _key The key that indexes the value
     */
    function getBytes(bytes32 _key) external view returns(bytes memory) {
        return _bytesStorage[_key];
    }

    /**
     * @notice Sets the value of a bytes32 corresponding to a key
     * @param _key The key that indexes the value
     */
    function setBytes(bytes32 _key, bytes calldata _value) onlyConnectedContract external returns (bool) {
        _bytesStorage[_key] = _value;
        return true;
    }

    /**
     * @notice Deletes the value of a bytes32 corresponding to a key
     * @param _key The key that indexes the value
     */
    function deleteBytes(bytes32 _key) onlyConnectedContract external returns (bool) {
        delete _bytesStorage[_key];
        return true;
    }

    // bool

    /**
     * @notice Reads the value of a bool corresponding to a key
     * @param _key The key that indexes the value
     */
    function getBool(bytes32 _key) external view returns(bool) {
        return _boolStorage[_key];
    }

    /**
     * @notice Sets the value of a bool corresponding to a key
     * @param _key The key that indexes the value
     */
    function setBool(bytes32 _key, bool _value) onlyConnectedContract external returns (bool) {
        _boolStorage[_key] = _value;
        return true;
    }

    /**
     * @notice Deletes the value of a bool corresponding to a key
     * @param _key The key that indexes the value
     */
    function deleteBool(bytes32 _key) onlyConnectedContract external returns (bool) {
        delete _boolStorage[_key];
        return true;
    }

    // string

    /**
     * @notice Reads the value of a string corresponding to a key
     * @param _key The key that indexes the value
     */
    function getString(bytes32 _key) external view returns(string memory) {
        return _stringStorage[_key];
    }

    /**
     * @notice Sets the value of a string corresponding to a key
     * @param _key The key that indexes the value
     */
    function setString(bytes32 _key, string calldata _value) onlyConnectedContract external returns (bool) {
        _stringStorage[_key] = _value;
        return true;
    }

    /**
     * @notice Deletes the value of a string corresponding to a key
     * @param _key The key that indexes the value
     */
    function deleteString(bytes32 _key) onlyConnectedContract external returns (bool) {
        delete _stringStorage[_key];
        return true;
    }

}