pragma solidity ^0.4.18;

import './math/SafeMath.sol';
import "./ownership/Owners.sol";
import "./tokens/REIDAOMintableBurnableLockableToken.sol";
import "./registries/AddressesEternalStorage.sol";
import "./registries/CRPAllocationConfig.sol";
import "./registries/CRPGenerationConfig.sol";

contract CRPGeneration is Owners {
  using SafeMath for uint256;

  enum State { Active, Inactive }
  State public state;
  REIDAOMintableBurnableLockableToken crvToken;
  REIDAOMintableBurnableLockableToken crpToken;

  AddressesEternalStorage eternalStorage;
  CRPGenerationConfig crpGenerationConfig;
  CRPAllocationConfig crpAllocationConfig;

  function CRPGeneration(AddressesEternalStorage _eternalStorage) public {
    state = State.Active;
    eternalStorage = _eternalStorage;
    crvToken = REIDAOMintableBurnableLockableToken(eternalStorage.getEntry("CRVToken"));
    crpToken = REIDAOMintableBurnableLockableToken(eternalStorage.getEntry("CRPToken"));
  }

  //to be call to generate all available tokens
  function () public payable {
    require(state == State.Active);
    generateCRP("default", crvToken.balanceOf(msg.sender));
  }

  function generateCRP(bytes32 _plan, uint crvToLock) public payable {
    uint transferrableCRV = crvToken.transferableTokens(msg.sender);
    require (crvToLock <= transferrableCRV);

    crpGenerationConfig = CRPGenerationConfig(eternalStorage.getEntry("CRPGenerationConfig"));
    crpAllocationConfig = CRPAllocationConfig(eternalStorage.getEntry("CRPAllocationConfig"));
    var (crpPerCrv, crvLockPeriod, initPct, subseqPct, subseqFreq, subseqFreqIntervalDays, isActive) = crpGenerationConfig.configs(_plan);
    require(isActive);

    crvToken.lockTokens(msg.sender, crvToLock, now + crvLockPeriod);

    uint crpToMint = crvToLock.mul(crpPerCrv);
    uint crpForTokenHolder    = crpToMint.mul(crpAllocationConfig.getConfig("tokenHolder")).div(100);

    //release 50% CRP allocated for token holder immediately
    crpToken.mint(msg.sender, crpForTokenHolder.mul(initPct).div(100));

    //release remaining CRP allocated for token holder in 5 batches.
    for (uint i=0; i<subseqFreq; i++) {
      crpToken.mintAndLockTokens(msg.sender, crpForTokenHolder.mul(subseqPct).div(100), now + (subseqFreqIntervalDays * (i+1)));
    }
    mintTokensForOtherParties(crpToMint);
  }

  function mintTokensForOtherParties(uint crpToMint) internal {
    uint crpForCrowdvillaNpo  = crpToMint.mul(crpAllocationConfig.getConfig("crowdvillaNpo")).div(100);
    uint crpForCrowdvillaOps  = crpToMint.mul(crpAllocationConfig.getConfig("crowdvillaOps")).div(100);
    uint crpForReidao         = crpToMint.mul(crpAllocationConfig.getConfig("reidao")).div(100);

    crpToken.mint(eternalStorage.getEntry("CRPWalletCrowdvillaNpo"), crpForCrowdvillaNpo);
    crpToken.mint(eternalStorage.getEntry("CRPWalletCrowdvillaOps"), crpForCrowdvillaOps);
    crpToken.mint(eternalStorage.getEntry("CRPWalletReidao"), crpForReidao);
  }

  function activateState() public ownerOnly {
    state = State.Active;
  }
  function inactivateState() public ownerOnly {
    state = State.Inactive;
  }
  function readCRPGenerationConfig(bytes32 _plan) internal view returns (uint,uint,uint,uint,uint,uint,bool) {
    return crpGenerationConfig.configs(_plan);
  }

}
