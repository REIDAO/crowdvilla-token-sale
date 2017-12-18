pragma solidity ^0.4.18;

import "./REIDAOMintableToken.sol";

contract REIToken is REIDAOMintableToken {
  string public name = "REI Token";
  string public symbol = "REI";

  mapping (uint => bool) tokensReleased;
  address walletREIDAO = 0x19BBe5157ffdf6Efa4C84810e7d2AE25832fF45D;

  function assignToREIDAO() public ownerOnly {
    uint index;
    uint amount = 200000 * 10**decimals;
    if (block.timestamp >= 1640995200) {
      //for WAVE 4
      //after 01/01/2022 @ 12:00am (UTC)
      index = 0;
      amount = 150000 * 10**decimals;
    } else if (block.timestamp >= 1609459200) {
      //for WAVE 3
      //after 01/01/2021 @ 12:00am (UTC)
      index = 1;
    } else if (block.timestamp >= 1577836800) {
      //for WAVE 2
      //after 01/01/2020 @ 12:00am (UTC)
      index = 2;
    } else {
      //for WAVE 1
      index = 3;
    }
    require(!tokensReleased[index]);
    mint(walletREIDAO, amount);
    tokensReleased[index] = true;
  }
}
