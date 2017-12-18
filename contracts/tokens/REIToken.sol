pragma solidity ^0.4.18;

import "./REIDAOMintableToken.sol";

contract REIToken is REIDAOMintableToken {
  string public name = "REI Token";
  string public symbol = "REI";

  mapping (uint => bool) tokensReleased;
  address walletREIDAO = 0x19BBe5157ffdf6Efa4C84810e7d2AE25832fF45D;

  function assignToREIDAO() public ownerOnly {
    uint index;
    uint amount = 200000 * 10**8;
    if (block.timestamp >= 1609459200) {
      //after 01/01/2021 @ 12:00am (UTC)
      index = 0;
    } else if (block.timestamp >= 1577836800) {
      //after 01/01/2020 @ 12:00am (UTC)
      index = 1;
    } else if (block.timestamp >= 1546300800) {
      //after 01/01/2019 @ 12:00am (UTC)
      index = 2;
    } else {
      //for current assignment
      index = 3;
      amount = 150000 * 10**8;
    }
    require(!tokensReleased[index]);
    mint(walletREIDAO, amount);
    tokensReleased[index] = true;
  }
}
