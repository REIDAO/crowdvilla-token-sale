pragma solidity ^0.4.18;

import './BurnableToken.sol';

contract REIDAOBurnableToken is BurnableToken {

  mapping (address => bool) public hostedWallets;

  function burn(uint256 _value) public hostedWalletsOnly {
    return super.burn(_value);
  }

  function addHostedWallet(address _wallet) public {
    hostedWallets[_wallet] = true;
  }
  function removeHostedWallet(address _wallet) public {
    hostedWallets[_wallet] = false;
  }

  modifier hostedWalletsOnly {
    require(hostedWallets[msg.sender]==true);
    _;
  }
}
