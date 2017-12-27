pragma solidity ^0.4.18;

import "./ownership/Owners.sol";

contract ReferrerAcct is Owners(false) {
  bytes32 public code;
  address public referrerWallet;
  address public crowdvillaWallet;

  event ETHReceived(uint amount);
  event ETHSent(address recipient, uint amount);

  function ReferrerAcct(bytes32 _code, address _referrerWallet, address _crowdvillaWallet) public {
    code = _code;
    referrerWallet = _referrerWallet;
    crowdvillaWallet = _crowdvillaWallet;
  }

  function() public payable {
    ETHReceived(msg.value);
  }

  function updateReferrerWallet(address _newWallet) public ownerOnly {
    referrerWallet = _newWallet;
  }

  function updateCrowdvillaWallet(address _newWallet) public ownerOnly {
    crowdvillaWallet = _newWallet;
  }

  function sendToReferrer(uint _amount) public ownerOnly {
    require(_amount <= this.balance);
    referrerWallet.transfer(_amount);
    ETHSent(referrerWallet, _amount);
  }

  function sendAllToReferrer() public ownerOnly {
    require(this.balance>0);
    uint amount = this.balance;
    referrerWallet.transfer(amount);
    ETHSent(referrerWallet, amount);
  }

  function sendToCrowdvilla(uint _amount) public ownerOnly {
    require(_amount <= this.balance);
    crowdvillaWallet.transfer(_amount);
    ETHSent(crowdvillaWallet, _amount);
  }

  function sendAllToCrowdvilla() public ownerOnly {
    require(this.balance>0);
    uint amount = this.balance;
    crowdvillaWallet.transfer(amount);
    ETHSent(crowdvillaWallet, amount);
  }
}
