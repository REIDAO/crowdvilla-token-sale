pragma solidity ^0.4.18;

import "./REIDAOMintableLockableToken.sol";
import "./REIDAOBurnableToken.sol";

contract REIDAOMintableBurnableLockableToken is REIDAOMintableLockableToken, REIDAOBurnableToken {

  /**
   * @dev adds hosted wallet, can only be done by owners.
   * @param _wallet address the address to be added
   */
  function addHostedWallet(address _wallet) public ownerOnly {
    return super.addHostedWallet(_wallet);
  }

  /**
   * @dev removes hosted wallet, can only be done by owners.
   * @param _wallet address the address to be removed
   */
  function removeHostedWallet(address _wallet) public ownerOnly {
    return super.removeHostedWallet(_wallet);
  }

  /**
   * @dev burns tokens, can only be done by hosted wallets
   * @param _value uint256 the amount of tokens to be burned
   */
  function burn(uint256 _value) public canTransfer(msg.sender, _value) {
    return super.burn(_value);
  }
}
