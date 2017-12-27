pragma solidity ^0.4.18;

contract Owners {

  mapping (address => bool) public owners;

  event OwnerAdded(address indexed owner);
  event OwnerRemoved(address indexed owner);

  function Owners() public {
    owners[0x23B599A0949C6147E05C267909C16506C7eFF229] = true;
    owners[0x286A70B3E938FCa244208a78B1823938E8e5C174] = true;
  }

  function addOwner(address _address) public ownerOnly {
    OwnerAdded(_address);
    owners[_address] = true;
  }

  function removeOwner(address _address) public ownerOnly {
    OwnerRemoved(_address);
    owners[_address] = false;
  }

  modifier ownerOnly {
    require(owners[msg.sender]);
    _;
  }

}
