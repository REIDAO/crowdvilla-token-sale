pragma solidity ^0.4.24;


import "./StandardToken.sol";
import "../ownership/Owners.sol";


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Owners(true) {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event MintStarted();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) external ownerOnly canMint onlyPayloadSize(2 * 32) returns (bool) {
    return internalMint(_to, _amount);
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public ownerOnly canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

  /**
   * @dev Function to start minting new tokens.
   * @return True if the operation was successful.
   */
  function startMinting() public ownerOnly returns (bool) {
    mintingFinished = false;
    emit MintStarted();
    return true;
  }

  function internalMint(address _to, uint256 _amount) internal returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
}
