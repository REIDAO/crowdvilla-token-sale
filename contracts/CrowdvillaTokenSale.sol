pragma solidity ^0.4.18;

import './math/SafeMath.sol';
import "./tokens/REIDAOMintableBurnableLockableToken.sol";
import "./tokens/REIDAOMintableToken.sol";

contract CrowdvillaTokenSale is Owners {
  using SafeMath for uint256;
  //TODO use safemath for all

  uint public totalFund;
  uint public uniqueContributors;
  uint public currentStretchGoal;
  uint public minContribution;
  uint public crvPerEth;
  uint public reiPerEth;
  uint public mgmtFeePercentage;
  uint public saleEndBlock;
  uint public totalReferralMultisig;
  uint[] public stretchGoals;

  address public deployer;
  address public opsAdmin;
  address public crowdvillaWallet;
  address public crvTokenAddr;
  address public crpTokenAddr;
  address public reiTokenAddr;
  address walletREIDAO = 0x19BBe5157ffdf6Efa4C84810e7d2AE25832fF45D;
  mapping (address => Whitelist) public whitelist;
  mapping (bytes32 => address) public referralMultisig;
  mapping (uint => mapping (uint => uint)) public contributionsPerStretchGoal; //earlyRegistrant => stretch-goals => value
  mapping (address => uint) public contributionsPerAddress;
  mapping (address => mapping (uint => uint)) public contributions;
  mapping (address => uint) public contributorIndex;
  mapping (uint => address) public reversedContributorIndex;
  mapping (address => bool) public tokensCollected;

  event Contribute(uint blkNo, uint blkTs, address indexed contributor, address indexed tokensale, uint amount, bytes32 referralCode);
  event Whitelisted(uint blkNo, uint blkTs, address indexed contributor, bool isEarlyRegistrant, bytes32 referralCode);
  event WhitelistChanged(address indexed _old, address indexed _new);

  enum State { TokenSale, End, Collection }
  State public state;

  REIDAOMintableBurnableLockableToken crvToken;
  REIDAOMintableBurnableLockableToken crpToken;
  REIDAOMintableToken reiToken;

  struct Whitelist {
    bool whitelisted;
    bool isEarlyRegistrant;
    bytes32 referralCode;
  }

  function CrowdvillaTokenSale(
      uint _stretchGoal1,
      uint _stretchGoal2,
      uint _stretchGoal3,
      address _opsAdmin,
      address _wallet,
      address _crvTokenAddr,
      address _crpTokenAddr,
      address _reiTokenAddr) public {
    deployer = msg.sender;
    state = State.TokenSale;

    opsAdmin = address(_opsAdmin);
    crowdvillaWallet = address(_wallet);
    crvTokenAddr = address(_crvTokenAddr);
    crpTokenAddr = address(_crpTokenAddr);
    reiTokenAddr = address(_reiTokenAddr);
    crvToken = REIDAOMintableBurnableLockableToken(crvTokenAddr);
    crpToken = REIDAOMintableBurnableLockableToken(crpTokenAddr);
    reiToken = REIDAOMintableToken(reiTokenAddr);

    minContribution = 1 ether;
    crvPerEth = 400 * (10**crvToken.decimals());
    reiPerEth = 5 * (10**reiToken.decimals());
    mgmtFeePercentage = 20;
    saleEndBlock = 5280000; //appox end of Mar 2018
    stretchGoals = [_stretchGoal1 * 1 ether, _stretchGoal2 * 1 ether, _stretchGoal3 * 1 ether];
  }


  // public - START ------------------------------------------------------------
  function () public payable {
    if (msg.value>0) {
      // for accepting fund
      require(isInWhitelist(msg.sender));
      require(msg.value >= minContribution);
      require(state == State.TokenSale);

      if (block.number >= saleEndBlock) {
        setEndState();
        msg.sender.transfer(msg.value);
      } else {
        totalFund = totalFund.add(msg.value);

        uint earlyRegistrantIndex = 0;
        if (whitelist[msg.sender].isEarlyRegistrant) {
          earlyRegistrantIndex = 1;
        }

        contributions[msg.sender][currentStretchGoal] = contributions[msg.sender][currentStretchGoal].add(msg.value);

        contributionsPerStretchGoal[earlyRegistrantIndex][currentStretchGoal] = contributionsPerStretchGoal[earlyRegistrantIndex][currentStretchGoal].add(msg.value);
        contributionsPerAddress[msg.sender] = contributionsPerAddress[msg.sender].add(msg.value);
        bytes32 referralCode = whitelist[msg.sender].referralCode;
        logContributeEvent(msg.sender, msg.value, referralCode);

        if (referralCode == bytes32(0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563)) {
          //no referral code
          crowdvillaWallet.transfer(msg.value);
        } else {
          //referral code exist, sending 99% to our wallet. 1% to multisig with arbiter
          uint crowdvillaAmount = (msg.value.mul(99)).div(100);
          crowdvillaWallet.transfer(crowdvillaAmount);
          referralMultisig[referralCode].transfer(msg.value.sub(crowdvillaAmount));
        }

        // to increase the currentStrechGoal targetted if the current one has been reached.
        //  also safe-guard if multiple stretch goals reached with a single contribution.
        // to end the token sale if it has reached the last stretch goal.
        for (uint currGoal = currentStretchGoal; currGoal < stretchGoals.length; currGoal++) {
          if (totalFund >= stretchGoals[currGoal] && currentStretchGoal != stretchGoals.length) {
            currentStretchGoal++;
          }
          if (currentStretchGoal == stretchGoals.length) {
            setEndState();
          }
        }

        if (contributorIndex[msg.sender]==0) {
          uniqueContributors++;
          contributorIndex[msg.sender] = uniqueContributors;
          reversedContributorIndex[uniqueContributors] = msg.sender;
        }
      }
    } else {
      // for tokens collection
      require(state == State.Collection);
      require(!tokensCollected[msg.sender]);
      uint promisedCRVToken = getPromisedCRVTokenAmount(msg.sender);
      require(promisedCRVToken>0);
      require(crvToken.mint(msg.sender, promisedCRVToken));
      require(crpToken.mint(msg.sender, promisedCRVToken));
      require(reiToken.mint(msg.sender, getPromisedREITokenAmount(msg.sender)));
      tokensCollected[msg.sender] = true;
    }
  }

  function getPromisedCRVTokenAmount(address _contributor) public constant returns (uint) {
    uint val;

    uint earlyRegistrantBonus = 0;
    if (whitelist[_contributor].isEarlyRegistrant)
      earlyRegistrantBonus = 1;

    for (uint i=0; i<=currentStretchGoal; i++) {
      val += (contributions[_contributor][i] * crvPerEth * (100 + ((currentStretchGoal-i + earlyRegistrantBonus) * 10))/100) / 1 ether;
    }
    return val;
  }

  function getPromisedREITokenAmount(address _contributor) public constant returns (uint) {
    uint val;
    uint totalEthContributions;
    for (uint i=0; i<=currentStretchGoal; i++) {
      totalEthContributions = totalEthContributions.add(contributions[_contributor][i]);
    }
    val = (totalEthContributions.mul(reiPerEth)).div(1 ether);

    return val;
  }

  function getREIDAODistributionTokenAmount() public constant returns (uint) {
    //contributionsPerStretchGoal index 0 is for non-earlyRegistrant
    //contributionsPerStretchGoal index 1 is for earlyRegistrant
    uint val;
    for (uint i=0; i<=currentStretchGoal; i++) {
      val += (contributionsPerStretchGoal[0][i] * crvPerEth * (100 + ((currentStretchGoal-i) * 10))/100) / 1 ether;
    }
    for (i=0; i<=currentStretchGoal; i++) {
      val += (contributionsPerStretchGoal[1][i] * crvPerEth * (100 + ((currentStretchGoal-i + 1) * 10))/100) / 1 ether;
    }
    uint total = (val.mul(100)).div(100 - mgmtFeePercentage);
    val = total.sub(val);
    return val;
  }

  /**
   * @dev Checks if `_contributor` is in the whitelist.
   * @param _contributor address The address of contributor.
   */
  function isInWhitelist(address _contributor) public constant returns (bool) {
    return (whitelist[_contributor].whitelisted == true);
  }
  // public - END --------------------------------------------------------------


  // ownerOnly - START ---------------------------------------------------------
  function collectREIDAODistribution() public ownerOnly {
    require(!tokensCollected[walletREIDAO]);
    uint tokenAmount = getREIDAODistributionTokenAmount();
    require(crvToken.mint(walletREIDAO, tokenAmount));
    require(crpToken.mint(walletREIDAO, tokenAmount));
    tokensCollected[walletREIDAO] = true;
  }

  function updateSaleEndBlock(uint _saleEndBlock) public ownerOnly {
    saleEndBlock = _saleEndBlock;
  }

  function endTokenSale() public ownerOnly {
    setEndState();
  }

  function startCollection() public ownerOnly {
    state = State.Collection;
  }

  /**
   * @dev Allows owners to update `_opsAdmin` as new opsAdmin.
   * @param _opsAdmin address The address of new opsAdmin.
   */
  function updateOpsAdmin(address _opsAdmin) public ownerOnly {
    opsAdmin = _opsAdmin;
  }

  /**
   * @dev Allows authorized signatories to update contributor address.
   * @param _old address the old contributor address.
   * @param _new address the new contributor address.
   */
  function updateContributorAddress(address _old, address _new) public ownerOnly {
    require (state != State.Collection);
    whitelist[_new] = Whitelist(whitelist[_old].whitelisted, whitelist[_old].isEarlyRegistrant, whitelist[_old].referralCode);
    uint currentContribution;

    bool contributionFound;
    for (uint i=0; i<=currentStretchGoal; i++) {
      currentContribution = contributions[_old][i];
      if (currentContribution > 0) {
        contributions[_old][i] = 0;
        contributions[_new][i] += currentContribution;
        contributionsPerAddress[_old] -= currentContribution;
        contributionsPerAddress[_new] += currentContribution;
        logContributeEvent(_new, currentContribution, whitelist[_old].referralCode);

        contributionFound = true;
      }
    }
    removeFromWhitelist(_old);

    if (contributionFound) {
      if (contributorIndex[_new]==0) {
        uniqueContributors++;
        contributorIndex[_new] = uniqueContributors;
        reversedContributorIndex[uniqueContributors] = _new;
      }
    }
    WhitelistChanged(_old, _new);
  }
  // ownerOnly - END -----------------------------------------------------------


  // opsAdmin - START ----------------------------------------------------------
  /**
   * @dev Allows opsAdmin to add `_contributor` to the whitelist.
   * @param _contributor address The address of contributor.
   * @param _earlyRegistrant bool If contributor is early registrant (registered before public sale).
   * @param _referralCode bytes32 The referral code. Empty String if not provided.
   */
  function addToWhitelist(address _contributor, bool _earlyRegistrant, bytes32 _referralCode) public opsAdminOnly {
    whitelist[_contributor] = Whitelist(true, _earlyRegistrant, keccak256(_referralCode));
    Whitelisted(block.number, block.timestamp, _contributor, _earlyRegistrant, keccak256(_referralCode));
  }

  /**
   * @dev Allows opsAdmin to register `_multisigAddr` as multisig wallet address for referral code `_referralCode`.
   * @param _referralCode bytes32 The referral code. Should not be empty since it should have value.
   * @param _multisigAddr address The address of multisig wallet.
   */
  function registerReferralMultisig(bytes32 _referralCode, address _multisigAddr) public opsAdminOnly {
    referralMultisig[keccak256(_referralCode)] = _multisigAddr;
    totalReferralMultisig++;
  }
  // opsAdmin - END ------------------------------------------------------------


  // internal - START ----------------------------------------------------------
  function setEndState() internal {
    state = State.End;
  }

  /**
   * @dev Allows authorized signatories to remove `_contributor` from the whitelist.
   * @param _contributor address The address of contributor.
   */
  function removeFromWhitelist(address _contributor) internal {
    whitelist[_contributor].whitelisted = false;
    whitelist[_contributor].isEarlyRegistrant = false;
  }

  function logContributeEvent(address _contributor, uint _amount, bytes32 _referralCode) internal {
    Contribute(block.number, block.timestamp, _contributor, this, _amount, _referralCode);
  }
  // internal - END ------------------------------------------------------------


  // modifier - START ----------------------------------------------------------
  /**
   * @dev Modifier that throws if sender is not opsAdmin.
   */
  modifier opsAdminOnly {
    require(msg.sender == opsAdmin);
    _;
  }
  // modifier - END ------------------------------------------------------------
}
