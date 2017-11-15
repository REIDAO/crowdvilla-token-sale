pragma solidity ^0.4.17;

contract CrowdvillaTokenSale {

  uint public totalFund;
  uint public uniqueContributors;
  uint public currentStretchGoal;
  uint public minContribution = 1 ether;
  uint public rcvPerEth = 400 * 10**8;
  uint public reiPerEth = 5 * 10**8;
  uint public mgmtFeePercentage = 20;
  uint public saleStartBlock;
  uint public saleEndBlock;
  uint[] public stretchGoals = [100000 ether, 2500000 ether, 5000000 ether];

  address public whitelister;
  mapping (address => bool) public whitelist;
  mapping (uint => uint) public contributionsPerStretchGoal;
  mapping (address => uint) public contributionsPerAddress;
  mapping (address => mapping (uint => uint)) public contributions;
  mapping (address => uint) public contributorIndex;
  mapping (uint => address) public reversedContributorIndex;

  event Contribute(address indexed contributor, uint amount);

  enum State { Initial, TokenSale, End, Collection }
  State public state;

  function CrowdvillaTokenSale() {
    state = State.Initial;
    saleStartBlock = 40000000;
    saleEndBlock   = 45000000;

    //TODO add whitelister
    whitelister = address(0x0);
  }

  function () public payable {
    if (msg.value>0) {
      // for accepting fund
      require(isInWhitelist(msg.sender));
      require(msg.value >= minContribution);
      require(state == State.Initial || state == State.TokenSale);

      if (state == State.Initial && block.number >= saleStartBlock) {
        state = State.TokenSale;
      }
      if (state == State.TokenSale) {
        if (block.number >= saleEndBlock) {
          setEndState();
          msg.sender.transfer(msg.value);
        } else {
          totalFund += msg.value;
          contributions[msg.sender][currentStretchGoal] += msg.value;
          contributionsPerStretchGoal[currentStretchGoal] += msg.value;
          contributionsPerAddress[msg.sender] += msg.value;
          logContributeEvent(msg.sender, msg.value);
          if (totalFund >= stretchGoals[currentStretchGoal]) {
            currentStretchGoal++;
          }

          if (currentStretchGoal == stretchGoals.length) {
            setEndState();
          }

          if (contributorIndex[msg.sender]==0) {
            uniqueContributors++;
            contributorIndex[msg.sender] = uniqueContributors;
            reversedContributorIndex[uniqueContributors] = msg.sender;
          }
        }
      }
    } else {
      require(state == State.Collection);
      // for tokens collection
    }
  }

  function getPromisedCRVTokenAmount() public constant returns (uint) {
    uint val;
    for (uint i=0; i<=currentStretchGoal; i++) {
      val += (contributions[msg.sender][i] * rcvPerEth * (100 + ((currentStretchGoal-i) * 10))/100) / 1 ether;
    }
    return val;
  }

  function getMgmtFeeTokenAmount() public constant returns (uint) {
    uint val;
    for (uint i=0; i<=currentStretchGoal; i++) {
      val += (contributionsPerStretchGoal[i] * rcvPerEth * (100 + ((currentStretchGoal-i) * 10))/100) / 1 ether;
    }
    uint total = (val * 100) / (100 - mgmtFeePercentage);
    val = total - val;
    return val;
  }

  function adminUpdateSaleEndBlock (uint _saleEndBlock) {
    //TODO add access-control
    saleEndBlock = _saleEndBlock;
  }

  function adminSetSendState() {
    //TODO add access-control
    setEndState();
  }

  function setEndState() internal {
    state = State.End;
  }

  /**
   * @dev Allows authorized signatories to update `_new` as new whitelister.
   * @param _whitelister address The address of new whitelister.
   */
  function adminUpdateWhitelister(address _whitelister) {
    //TODO add access-control
    whitelister = _whitelister;
  }

  /**
   * @dev Allows whitelister to add `_contributor` to the whitelist.
   * @param _contributor address The address of contributor.
   */
  function addToWhitelist(address _contributor) whitelisterOnly {
    whitelist[_contributor] = true;
  }

  /**
   * @dev Allows authorized signatories to update contributor address.
   * @param _old address the old contributor address.
   * @param _new address the new contributor address.
   */
  function adminUpdateContributorAddress(address _old, address _new) {
    //TODO add access-control
    require (state != State.Collection);
    removeFromWhitelist(_old);
    addToWhitelist(_new);
    uint currentContribution;
    for (uint i=0; i<=currentStretchGoal; i++) {
      currentContribution = contributions[_old][i];
      if (currentContribution > 0) {
        contributions[_old][i] = 0;
        contributions[_new][i] += currentContribution;
        contributionsPerAddress[_old] -= currentContribution;
        contributionsPerAddress[_new] += currentContribution;
        logContributeEvent(_new, currentContribution);
      }
    }
  }

  /**
   * @dev Allows authorized signatories to remove `_contributor` from the whitelist.
   * @param _contributor address The address of contributor.
   */
  function removeFromWhitelist(address _contributor) internal {
    whitelist[_contributor] = false;
  }

  /**
   * @dev Checks if `_contributor` is in the whitelist.
   * @param _contributor address The address of contributor.
   */
  function isInWhitelist(address _contributor) constant returns (bool) {
    return (whitelist[_contributor] == true);
  }

  /**
   * @dev Modifier that throws if sender is not whitelister.
   */
  modifier whitelisterOnly {
    require(msg.sender == whitelister);
    _;
  }

  function getPromisedREITokenAmount() public constant returns (uint) {
    uint val;
    uint totalEthContributions;
    for (uint i=0; i<=currentStretchGoal; i++) {
      totalEthContributions += contributions[msg.sender][i];
    }
    val = totalEthContributions * reiPerEth / 1 ether;

    return val;
  }

  function logContributeEvent(address _contributor, uint _amount) internal {
    Contribute(_contributor, _amount);
  }
}
