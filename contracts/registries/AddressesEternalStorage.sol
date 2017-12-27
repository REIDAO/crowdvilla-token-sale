pragma solidity ^0.4.18;

import "../ownership/Owners.sol";

contract AddressesEternalStorage is Owners(true) {

  event EntryAdded(bytes32 key, address value);
  event EntryDeleted(bytes32 key);

  mapping (bytes32 => address) public addressStorage;

  function getEntry(bytes32 _key) public constant returns (address) {
    return addressStorage[_key];
  }

  function addEntry(bytes32 _key, address _value) public ownerOnly {
    addressStorage[_key] = _value;
    EntryAdded( _key, _value);
  }

  function deleteEntry(bytes32 _key) public ownerOnly {
    if (addressStorage[_key]!=0x0) {
      addressStorage[_key] = 0x0;
      EntryDeleted(_key);
    }
  }
}
