pragma solidity ^0.4.24;


contract Owners {

  mapping (address => bool) public owners;
  uint public ownersCount;
  uint public minOwnersRequired = 2;

  event OwnerAdded(address indexed owner);
  event OwnerRemoved(address indexed owner);

  /**
   * @dev initializes contract
   * @param withDeployer bool indicates whether deployer is part of owners
   */
  constructor(bool withDeployer) public {
    if (withDeployer) {
      ownersCount++;
      owners[msg.sender] = true;
    }
    owners[0x23B599A0949C6147E05C267909C16506C7eFF229] = true;
    owners[0x286A70B3E938FCa244208a78B1823938E8e5C174] = true;
    ownersCount = ownersCount + 2;
  }

  /**
   * @dev adds owner, can only by done by owners only
   * @param _address address the address to be added
   */
  function addOwner(address _address) public ownerOnly {
    require(_address != address(0));
    owners[_address] = true;
    ownersCount++;
    emit OwnerAdded(_address);
  }

  /**
   * @dev removes owner, can only by done by owners only
   * @param _address address the address to be removed
   */
  function removeOwner(address _address) public ownerOnly notOwnerItself(_address) minOwners {
    require(owners[_address] == true);
    owners[_address] = false;
    ownersCount--;
    emit OwnerRemoved(_address);
  }

  /**
   * @dev checks if sender is owner
   */
  modifier ownerOnly {
    require(owners[msg.sender]);
    _;
  }

  modifier notOwnerItself(address _owner) {
    require(msg.sender != _owner);
    _;
  }

  modifier minOwners {
    require(ownersCount > minOwnersRequired);
    _;
  }

}
