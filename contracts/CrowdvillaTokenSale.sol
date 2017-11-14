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

  mapping (uint => uint) public contributionsPerStretchGoal;
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
  }

  function () public payable {
    if (msg.value>0) {
      // for accepting fund
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

  function setEndState() private {
    state = State.End;
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
