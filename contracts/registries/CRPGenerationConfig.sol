pragma solidity ^0.4.18;

import "../ownership/Owners.sol";

contract CRPGenerationConfig is Owners(true) {

  struct config {
    uint crpPerCrv;
    uint crvLockPeriod;
    uint initPct;
    uint subseqPct;
    uint subseqFreq;
    uint subseqFreqIntervalDays;
    bool isActive;
  }

  mapping(bytes32 => config) public configs;

  function CRPGenerationConfig() public {
    addConfig("default", 10, 26 weeks, 50, 10, 5, 30 days, true);
  }

  function addConfig(
    bytes32 _plan,
    uint _crpPerCrv,
    uint _crvLockPeriod,
    uint _initPct,
    uint _subseqPct,
    uint _subseqFreq,
    uint _subseqFreqIntervalDays,
    bool _isActive) public ownerOnly {
      configs[_plan].crpPerCrv = _crpPerCrv;
      configs[_plan].crvLockPeriod = _crvLockPeriod;
      configs[_plan].initPct = _initPct;
      configs[_plan].subseqPct = _subseqPct;
      configs[_plan].subseqFreq = _subseqFreq;
      configs[_plan].subseqFreqIntervalDays = _subseqFreqIntervalDays;
      configs[_plan].isActive = _isActive;
  }

  function activatePlan(bytes32 _plan) public ownerOnly {
    require(!configs[_plan].isActive);
    configs[_plan].isActive = true;
  }
  function inactivatePlan(bytes32 _plan) public ownerOnly {
    require(configs[_plan].isActive);
    configs[_plan].isActive = false;
  }
}
