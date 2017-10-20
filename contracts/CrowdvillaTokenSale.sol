pragma solidity ^0.4.17;

contract CrowdvillaTokenSale {

  uint public totalFund;
  uint public uniqueContributors;
  uint public currentStretchGoal;
  uint public recvPerEth = 400 * 10**8;
  uint public mgmtFeePercentage = 20;
  uint[] public stretchGoals = [3 ether, 7 ether, 12 ether];

  mapping (uint => uint) public contributionsPerStretchGoal;
  mapping (address => mapping (uint => uint)) public contributions;
  mapping (address => uint) public contributorIndex;
  mapping (uint => address) public reversedContributorIndex;

  event Contribute(address indexed contributor, uint amount);

  function () public payable {
    totalFund += msg.value;
    contributions[msg.sender][currentStretchGoal] += msg.value;
    contributionsPerStretchGoal[currentStretchGoal] += msg.value;
    Contribute(msg.sender, msg.value);
    if (currentStretchGoal < stretchGoals.length && totalFund >= stretchGoals[currentStretchGoal])
      currentStretchGoal++;

    if (contributorIndex[msg.sender]==0) {
      uniqueContributors++;
      contributorIndex[msg.sender] = uniqueContributors;
      reversedContributorIndex[uniqueContributors] = msg.sender;
    }
  }

  function getPromisedTokenAmount() public constant returns (uint) {
    uint val;
    for (uint i=0; i<=currentStretchGoal; i++) {
      val += (contributions[msg.sender][i] * recvPerEth * (100 + ((currentStretchGoal-i) * 10))/100) / 1 ether;
    }
    return val;
  }

  function getMgmtFeeTokenAmount() public constant returns (uint) {
    uint val;
    for (uint i=0; i<=currentStretchGoal; i++) {
      val += (contributionsPerStretchGoal[i] * recvPerEth * (100 + ((currentStretchGoal-i) * 10))/100) / 1 ether;
    }
    uint total = (val * 100) / (100 - mgmtFeePercentage);
    val = total - val;
    return val;
  }
}
