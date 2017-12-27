pragma solidity ^0.4.18;

import "../ownership/Owners.sol";

contract CRPAllocationConfig is Owners(true) {

  struct config {
    uint crpPerCrv;
    uint crvLockPeriod;
    uint initPct;
    uint subseqPct;
    uint subseqFreq;
    uint subseqFreqIntervalDays;
    bool isActive;
  }

  mapping(bytes32 => uint) public configs;

  function CRPAllocationConfig() public {
    addConfig("tokenHolder", 30);
    addConfig("crowdvillaNpo", 50);
    addConfig("crowdvillaOps", 15);
    addConfig("reidao", 5);
  }

  function addConfig(bytes32 _party, uint _allocation) public ownerOnly {
    configs[_party] = _allocation;
  }

  function getConfig(bytes32 _party) public view returns (uint) {
    return configs[_party];
  }

}
