pragma solidity ^0.4.18;

import './math/SafeMath.sol';
import "./ownership/Owners.sol";
import "./tokens/REIDAOMintableBurnableLockableToken.sol";
import "./registries/AddressesEternalStorage.sol";
import "./registries/PointAllocationConfig.sol";
import "./registries/PointGenerationConfig.sol";

contract PointGeneration is Owners(true) {
  using SafeMath for uint256;

  enum State { Active, Inactive }
  State public state;
  REIDAOMintableBurnableLockableToken crvToken;
  REIDAOMintableBurnableLockableToken point;
  bytes32 public defaultPlan;
  event GeneratePoints(address indexed sender, bytes32 plan, uint crvCommitted, uint crvLockedUntil);

  AddressesEternalStorage eternalStorage;
  PointGenerationConfig pointGenerationConfig;
  PointAllocationConfig pointAllocationConfig;

  /**
   * @dev initializes contract with parameter
   * @param       _eternalStorage AddressesEternalStorage the address of eternal storage
   */
  function PointGeneration(AddressesEternalStorage _eternalStorage) public {
    defaultPlan = "default";
    state = State.Active;
    eternalStorage = _eternalStorage;
    crvToken = REIDAOMintableBurnableLockableToken(eternalStorage.getEntry("CRVToken"));
    point = REIDAOMintableBurnableLockableToken(eternalStorage.getEntry("Point"));
  }

  /**
   * @notice generates points according to the default plan, for all CRV owned
   * @dev external method
   */
  function () external {
    generatePoint(defaultPlan, crvToken.balanceOf(msg.sender));
  }

  /**
   * @notice generates points according to the default plan, for all CRV owned
   * @dev external method
   */
  function generatePointPlan(bytes32 _plan) external {
    generatePoint(_plan, crvToken.balanceOf(msg.sender));
  }

  /**
   * @notice generates points according to the plan config (from PointGenerationConfig),
   * and according to the allocation config (from PointAllocationConfig).
   * eternalStorage stores the addresses of both config contracts.
   * Only proceed is the state of the contact is active, and the generation plan is active.
   * @dev public method
   * @param _plan bytes32 the name of the plan to be used to generate points
   * @param crvToLock uint total number of CRV tokens activated (to be locked)
   */
  function generatePoint(bytes32 _plan, uint crvToLock) public payable {
    require(state == State.Active);
    uint transferrableCRV = crvToken.transferableTokens(msg.sender);
    require (crvToLock <= transferrableCRV);

    pointGenerationConfig = PointGenerationConfig(eternalStorage.getEntry("PointGenerationConfig"));
    pointAllocationConfig = PointAllocationConfig(eternalStorage.getEntry("PointAllocationConfig"));
    var (pointPerCrv, crvLockPeriod, initPct, subseqPct, subseqFreq, subseqFreqIntervalDays, isActive) = pointGenerationConfig.configs(_plan);
    require(isActive);

    crvToken.lockTokens(msg.sender, crvToLock, now + crvLockPeriod);

    uint pointToMint = crvToLock.mul(pointPerCrv);
    uint pointForTokenHolder = pointToMint.mul(pointAllocationConfig.getConfig("tokenHolder")).div(100);

    //release immediate points allocation for token holder
    point.mint(msg.sender, pointForTokenHolder.mul(initPct).div(100));

    //release remaining points allocated for token holder in 5 batches.
    uint pointForTokenHolderSubseq = pointForTokenHolder.mul(subseqPct).div(100);
    for (uint i=0; i<subseqFreq; i++) {
      point.mintAndLockTokens(msg.sender, pointForTokenHolderSubseq, now + (subseqFreqIntervalDays * (i+1)));
    }
    mintTokensForOtherParties(pointToMint);
    GeneratePoints(msg.sender, _plan, crvToLock, now + crvLockPeriod);
  }

  /**
   * @notice mints points for parties other than token holders
   * @dev internal call only
   * @param pointToMint uint the total amount of generated points.
   */
  function mintTokensForOtherParties(uint pointToMint) internal {
    uint pointForCrowdvillaNpo  = pointToMint.mul(pointAllocationConfig.getConfig("crowdvillaNpo")).div(100);
    uint pointForCrowdvillaOps  = pointToMint.mul(pointAllocationConfig.getConfig("crowdvillaOps")).div(100);
    uint pointForReidao         = pointToMint.mul(pointAllocationConfig.getConfig("reidao")).div(100);

    point.mint(eternalStorage.getEntry("PointWalletCrowdvillaNpo"), pointForCrowdvillaNpo);
    point.mint(eternalStorage.getEntry("PointWalletCrowdvillaOps"), pointForCrowdvillaOps);
    point.mint(eternalStorage.getEntry("PointWalletReidao"), pointForReidao);
  }

  /**
   * @notice updates the default plan name.
   * @dev can only by called by owners
   * @param _defaultPlan bytes32 the name ot the new default plan
   */
  function changeDefaultPlan(bytes32 _defaultPlan) public ownerOnly {
    defaultPlan = _defaultPlan;
  }

  /**
   * @notice activates the state of contract.
   * @dev can only by called by owners
   */
  function activateState() public ownerOnly {
    state = State.Active;
  }

  /**
   * @notice deactivates the state of contract.
   * @dev can only by called by owners
   */
  function inactivateState() public ownerOnly {
    state = State.Inactive;
  }
}
