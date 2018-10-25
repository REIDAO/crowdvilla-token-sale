pragma solidity ^0.4.24;

import "../ownership/Owners.sol";


contract PointGenerationConfig is Owners(true) {

  struct Config {
    uint pointPerCrv;
    uint crvLockPeriod;
    uint initPct;
    uint subseqFreq;
    uint subseqFreqIntervalDays;
    bool isActive;
  }

  event ConfigAdded(
    bytes32 plan,
    uint pointPerCrv,
    uint crvLockPeriod,
    uint initPct,
    uint subseqFreq,
    uint subseqFreqIntervalDays
  );

  mapping(bytes32 => Config) public configs;

  /**
   * @dev initializes contract with default plan
   */
  constructor() public {
    addConfig("1", 100, 30 days, 50, 1, 30 days, true);
    addConfig("3", 375, 90 days, 50, 3, 30 days, true);
    addConfig("6", 900, 180 days, 50, 6, 30 days, true);
  }

  /**
   * @dev adds config
   * @param _plan bytes32 the plan name to be added
   * @param _pointPerCrv uint the amount of points generated per 1 CRV (multiplier in %)
   * @param _crvLockPeriod uint the locking period for CRV tokens
   * @param _initPct uint the percentage of points to be released immediately
   * @param _subseqFreq uint frequency of subsequent release of points
   * @param _subseqFreqIntervalDays uint the interval number of days `_subseqFreq` is applicable
   * @param _isActive bool indicates whether the plan is active
   */
  function addConfig(
    bytes32 _plan,
    uint _pointPerCrv,
    uint _crvLockPeriod,
    uint _initPct,
    uint _subseqFreq,
    uint _subseqFreqIntervalDays,
    bool _isActive) public ownerOnly {
    configs[_plan].pointPerCrv = _pointPerCrv;
    configs[_plan].crvLockPeriod = _crvLockPeriod;
    configs[_plan].initPct = _initPct;
    configs[_plan].subseqFreq = _subseqFreq;
    configs[_plan].subseqFreqIntervalDays = _subseqFreqIntervalDays;
    configs[_plan].isActive = _isActive;
    emit ConfigAdded(_plan, _pointPerCrv, _crvLockPeriod, _initPct, _subseqFreq, _subseqFreqIntervalDays);
  }

  /**
   * @dev activates plan
   * @param _plan bytes32 the plan to be activated
   */
  function activatePlan(bytes32 _plan) public ownerOnly {
    require(!configs[_plan].isActive);
    configs[_plan].isActive = true;
  }

  /**
   * @dev deactivates plan
   * @param _plan bytes32 the plan to be deactivated
   */
  function inactivatePlan(bytes32 _plan) public ownerOnly {
    require(configs[_plan].isActive);
    configs[_plan].isActive = false;
  }
}
