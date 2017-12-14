pragma solidity ^0.4.18;

import "./REIDAOMintableLockableToken.sol";
import "./REIDAOBurnableToken.sol";

contract REIDAOMintableBurnableLockableToken is REIDAOMintableLockableToken, REIDAOBurnableToken {

  function addHostedWallet(address _wallet) public ownerOnly {
    return super.addHostedWallet(_wallet);
  }
  function removeHostedWallet(address _wallet) public ownerOnly {
    return super.removeHostedWallet(_wallet);
  }
}
