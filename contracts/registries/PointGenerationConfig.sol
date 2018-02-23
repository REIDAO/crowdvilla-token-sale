pragma solidity ^0.4.18;

import "../ownership/Owners.sol";

contract PointGenerationConfig is Owners(true) {

  struct config {
    uint pointPerCrv;
    uint crvLockPeriod;
    uint initPct;
    uint subseqPct;
    uint subseqFreq;
    uint subseqFreqIntervalDays;
    bool isActive;
  }

  event ConfigAdded(bytes32 plan, uint pointPerCrv, uint crvLockPeriod, uint initPct, uint subseqPct, uint subseqFreq, uint subseqFreqIntervalDays);

  mapping(bytes32 => config) public configs;

  /**
   * @dev initializes contract with default plan
   */
  function PointGenerationConfig() public {
    addConfig("default", 10, 26 weeks, 50, 10, 5, 30 days, true);
  }

  /**
   * @dev adds config
   * @param _plan bytes32 the plan name to be added
   * @param _pointPerCrv uint the amount of points generated per 1 CRV
   * @param _crvLockPeriod uint the locking period for CRV tokens
   * @param _initPct uint the percentage of points to be released immediately
   * @param _subseqPct uint the percentage of points to be released subsequently
   * @param _subseqFreq uint frequency of subsequent release of points
   * @param _subseqFreqIntervalDays uint the interval number of days `_subseqFreq` is applicable
   * @param _isActive bool indicates whether the plan is active
   */
  function addConfig(
    bytes32 _plan,
    uint _pointPerCrv,
    uint _crvLockPeriod,
    uint _initPct,
    uint _subseqPct,
    uint _subseqFreq,
    uint _subseqFreqIntervalDays,
    bool _isActive) public ownerOnly {
      require(_initPct + (_subseqPct * _subseqFreq) == 100);
      configs[_plan].pointPerCrv = _pointPerCrv;
      configs[_plan].crvLockPeriod = _crvLockPeriod;
      configs[_plan].initPct = _initPct;
      configs[_plan].subseqPct = _subseqPct;
      configs[_plan].subseqFreq = _subseqFreq;
      configs[_plan].subseqFreqIntervalDays = _subseqFreqIntervalDays;
      configs[_plan].isActive = _isActive;
      ConfigAdded(_plan, _pointPerCrv, _crvLockPeriod, _initPct, _subseqPct, _subseqFreq, _subseqFreqIntervalDays);
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
