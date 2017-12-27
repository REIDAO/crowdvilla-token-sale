pragma solidity ^0.4.18;

import './math/SafeMath.sol';
import "./tokens/REIDAOMintableToken.sol";
import "./CrowdvillaTokenSale.sol";

contract REITokenSale is Owners(true) {
  using SafeMath for uint256;
  //TODO use safemath for all

  enum State { Stage1, Stage2, Stage3, Pause}
  State public state;

  address public deployer;
  address public reiTokenAddr;
  address public reidaoWallet;

  REIDAOMintableToken reiToken;
  CrowdvillaTokenSale crowdvillaTokenSale;
  uint[] public stageMinTokens;
  uint[] public stageTokenPrice;

  uint public stageAvailableTokens;
  uint public reiTokenMaxAmount;
  uint public reiTokenAllocatedToCrowdvilla;
  uint public reiTokenAllocatedToReidaoAssc;
  uint public reiTokenAllocatedToBounty;

  event Sale(uint indexed stage, address indexed contributor, uint amount, uint tokenAmount, uint refunded);

  function REITokenSale(
      address _reiTokenAddr,
      address _crowdvillaTokenSale,
      address _reidaoWallet,
      uint _stage1MinTokens,
      uint _stage2MinTokens,
      uint _stage3MinTokens,
      uint _stage1TokenPrice,
      uint _stage2TokenPrice,
      uint _stage3TokenPrice) public {
    deployer = msg.sender;

    reiTokenAddr = address(_reiTokenAddr);
    reiToken = REIDAOMintableToken(reiTokenAddr);
    crowdvillaTokenSale = CrowdvillaTokenSale(_crowdvillaTokenSale);
    reidaoWallet = _reidaoWallet;
    stageMinTokens = [_stage1MinTokens, _stage2MinTokens, _stage3MinTokens];
    stageTokenPrice = [_stage1TokenPrice, _stage2TokenPrice, _stage3TokenPrice];
    reiTokenMaxAmount = 5000000 * 10**reiToken.decimals();
    reiTokenAllocatedToCrowdvilla = crowdvillaTokenSale.totalFund() * 5 * 10**reiToken.decimals() / 1 ether;
    reiTokenAllocatedToReidaoAssc = 750000 * 10**reiToken.decimals();
    reiTokenAllocatedToBounty = 200000 * 10**reiToken.decimals();
  }

  // public - START ------------------------------------------------------------
  function () public payable {
    require(state != State.Pause);
    uint index = uint8(state);
    require(msg.value >= stageTokenPrice[index]);
    uint reiToMint = msg.value * 10**reiToken.decimals() / stageTokenPrice[index];
    uint refundAmount;
    if (reiToMint <= stageAvailableTokens) {
      stageAvailableTokens = stageAvailableTokens - reiToMint;
      reidaoWallet.transfer(msg.value);
      reiToken.mint(msg.sender, reiToMint);
    } else {
      reiToMint = stageAvailableTokens;
      reiToken.mint(msg.sender, reiToMint);
      uint acceptedAmount = (reiToMint * stageTokenPrice[index] /  10**reiToken.decimals());
      refundAmount = msg.value - acceptedAmount;
      reidaoWallet.transfer(acceptedAmount);
      msg.sender.transfer(refundAmount);
      stageAvailableTokens = 0;
    }
    Sale(index+1, msg.sender, msg.value, reiToMint, refundAmount);
    if (stageAvailableTokens == 0) {
      state = State.Pause;
    }
  }
  // public - END --------------------------------------------------------------


  // ownerOnly - START ---------------------------------------------------------
  function pauseTokenSale() public ownerOnly {
    state = State.Pause;
  }

  function startTokenSale(uint _stage) public ownerOnly {
    require(_stage>=1 && _stage<=3);
    if (_stage==1) {
      state = State.Stage1;
      stageAvailableTokens = reiTokenMaxAmount - reiTokenAllocatedToCrowdvilla - reiTokenAllocatedToReidaoAssc - reiTokenAllocatedToBounty - stageMinTokens[1] - stageMinTokens[2];
    } else if (_stage==2) {
      state = State.Stage2;
      stageAvailableTokens = stageAvailableTokens + stageMinTokens[1];
    } else if (_stage==3) {
      state = State.Stage3;
      stageAvailableTokens = stageAvailableTokens + stageMinTokens[2];
    }
  }
  // ownerOnly - END -----------------------------------------------------------
}
