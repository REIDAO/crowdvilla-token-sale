pragma solidity ^0.4.18;

import './math/SafeMath.sol';
import "./tokens/REIDAOMintableToken.sol";
import "./CrowdvillaTokenSale.sol";

contract REITokenSale is Owners(true) {
  using SafeMath for uint256;

  enum State { Stage1, Stage2, Stage3, Pause}
  State public state;
  State public pausedState;

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
  mapping (address => uint) public sales;

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

    uint reiTokenMaxUnit = 5000000;
    reiTokenMaxAmount = reiTokenMaxUnit.mul(10**reiToken.decimals());

    reiTokenAllocatedToCrowdvilla = crowdvillaTokenSale.totalFund().mul(5).mul(10**reiToken.decimals()).div(1 ether);

    uint reiTokenReidaoUnit = 750000;
    reiTokenAllocatedToReidaoAssc = reiTokenReidaoUnit.mul(10**reiToken.decimals());

    uint reiTokenBountyUnit = 200000;
    reiTokenAllocatedToBounty = reiTokenBountyUnit.mul(10**reiToken.decimals());
  }

  // public - START ------------------------------------------------------------
  function () public payable {
    require(state != State.Pause);
    uint index = uint8(state);
    require(msg.value >= stageTokenPrice[index]);
    uint reiToMint = msg.value.mul(10**reiToken.decimals()).div(stageTokenPrice[index]);
    uint refundAmount;
    if (reiToMint <= stageAvailableTokens) {
      stageAvailableTokens = stageAvailableTokens.sub(reiToMint);
      reidaoWallet.transfer(msg.value);
      reiToken.mint(msg.sender, reiToMint);
    } else {
      reiToMint = stageAvailableTokens;
      reiToken.mint(msg.sender, reiToMint);
      uint acceptedAmount = reiToMint.mul(stageTokenPrice[index]).div(10**reiToken.decimals());
      refundAmount = msg.value.sub(acceptedAmount);
      reidaoWallet.transfer(acceptedAmount);
      msg.sender.transfer(refundAmount);
      stageAvailableTokens = 0;
    }
    Sale(index.add(1), msg.sender, msg.value, reiToMint, refundAmount);
    sales[msg.sender] = sales[msg.sender].add(msg.value.sub(refundAmount));
    if (stageAvailableTokens == 0) {
      state = State.Pause;
    }
  }
  // public - END --------------------------------------------------------------


  // ownerOnly - START ---------------------------------------------------------
  function pauseTokenSale() public ownerOnly {
    pausedState = state;
    state = State.Pause;
  }

  function resumeTokenSale() public ownerOnly {
    require(state == State.Pause);
    state = pausedState;
  }
  function startTokenSale(uint _stage) public ownerOnly {
    require(_stage>=1 && _stage<=3);
    if (_stage==1) {
      state = State.Stage1;
      stageAvailableTokens = reiTokenMaxAmount.sub(reiTokenAllocatedToCrowdvilla).sub(reiTokenAllocatedToReidaoAssc).sub(reiTokenAllocatedToBounty).sub(stageMinTokens[1]).sub(stageMinTokens[2]);
    } else if (_stage==2) {
      state = State.Stage2;
      stageAvailableTokens = stageAvailableTokens.add(stageMinTokens[1]);
    } else if (_stage==3) {
      state = State.Stage3;
      stageAvailableTokens = stageAvailableTokens.add(stageMinTokens[2]);
    }
  }
  // ownerOnly - END -----------------------------------------------------------
}
