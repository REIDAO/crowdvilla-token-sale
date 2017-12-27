pragma solidity ^0.4.18;

contract Owners {

  mapping (address => bool) public owners;

  event OwnerAdded(address indexed owner);
  event OwnerRemoved(address indexed owner);

  function Owners(bool withDeployer) public {
    if (withDeployer) {
      owners[msg.sender] = true;
    }
    owners[0x23B599A0949C6147E05C267909C16506C7eFF229] = true;
    owners[0x286A70B3E938FCa244208a78B1823938E8e5C174] = true;
  }

  function addOwner(address _address) public ownerOnly {
    owners[_address] = true;
    OwnerAdded(_address);
  }

  function removeOwner(address _address) public ownerOnly {
    owners[_address] = false;
    OwnerRemoved(_address);
  }

  modifier ownerOnly {
    require(owners[msg.sender]);
    _;
  }

}
