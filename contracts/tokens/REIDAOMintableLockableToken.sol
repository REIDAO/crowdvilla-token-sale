pragma solidity ^0.4.18;

import "./REIDAOMintableToken.sol";

contract REIDAOMintableLockableToken is REIDAOMintableToken {

  struct TokenLock {
    uint256 value;
    uint lockedUntil;
  }

  mapping (address => TokenLock[]) public locks;

  /**
   * @dev Allows authorized callers to transfer `_value` tokens to `_to`, and lock them until timestamp `_lockUntil`.
   * @param _to address The address to be locked.
   * @param _value uint The amout of tokens to be locked.
   * @param _lockUntil uint The UNIX timestamp tokens are locked until.
   */
  function adminTransferAndLockTokens(address _to, uint256 _value, uint256 _lockUntil) public ownerOnly {
    require(_lockUntil > now);
    adminTransfer(_to, _value);
    adminLockTokens(_to, _value, _lockUntil);
  }

  /**
   * @dev Allows authorized callers to transfer the tokens. To be called before trading started.
   * @param _to address The recipient address of the tokens.
   * @param _value uint The amount of tokens to be transfered.
   */
  function adminTransfer(address _to, uint256 _value) public ownerOnly returns (bool) {
    return super.transfer(_to, _value);
  }

  /**
   * @dev Allows authorized callers to transfer `_value` amount of tokens (transfer-eligible) once trading has started.
   * @param _from address The sender address of the tokens.
   * @param _to address The recipient address of the tokens.
   * @param _value uint The amount of tokens to be transfered.
   */
  function adminTransferFrom(address _from, address _to, uint256 _value) public ownerOnly returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Allows authorized callers to lock `_value` tokens belong to `_to` until timestamp `_lockUntil`.
   * This function can be called independently of transferAndLockTokens(), hence the double checking of timestamp.
   * @param _to address The address to be locked.
   * @param _value uint The amout of tokens to be locked.
   * @param _lockUntil uint The UNIX timestamp tokens are locked until.
   */
  function adminLockTokens(address _to, uint256 _value, uint256 _lockUntil) public ownerOnly {
    require(_value <= balanceOf(_to));
    require(_lockUntil > now);
    locks[_to].push(TokenLock(_value, _lockUntil));
  }

  /**
   * @dev Allows authorized callers to mint `_value` tokens for `_to`, and lock them until timestamp `_lockUntil`.
   * @param _to address The address to which tokens to be minted and locked.
   * @param _value uint The amout of tokens to be minted and locked.
   * @param _lockUntil uint The UNIX timestamp tokens are locked until.
   */
  function adminMintAndLockTokens(address _to, uint256 _value, uint256 _lockUntil) public ownerOnly {
    require(_lockUntil > now);
    mint(_to, _value);
    adminLockTokens(_to, _value, _lockUntil);
  }

  /**
   * @dev Checks the amount of transferable tokens belongs to `_holder`.
   * @param _holder address The address to be checked.
   */
  function transferableTokens(address _holder) internal constant returns (uint256) {
    uint256 lockedTokens = getLockedTokens(_holder);
    if (lockedTokens==0) {
      return balanceOf(_holder);
    } else {
      return balanceOf(_holder).sub(lockedTokens);
    }
  }

  /**
   * @dev Retrieves the amount of locked tokens `_holder` has.
   * @param _holder address The address to be checked.
   */
  function getLockedTokens(address _holder) public constant returns (uint256) {
    uint256 numLocks = getTokenLocksCount(_holder);

    // shortcut for holder without locks
    if (numLocks == 0) return 0;

    // Iterate through all the locks the holder has
    uint256 lockedTokens = 0;
    for (uint256 i = 0; i < numLocks; i++) {
      if (locks[_holder][i].lockedUntil >= now) {
        lockedTokens = lockedTokens.add(locks[_holder][i].value);
      }
    }

    return lockedTokens;
  }

  /**
   * @dev Retrieves the number of token locks `_holder` has.
   * @param _holder address The address the token locks belongs to.
   * @return A uint256 representing the total number of locks.
   */
  function getTokenLocksCount(address _holder) internal constant returns (uint256 index) {
    return locks[_holder].length;
  }

  /**
   * @dev Modifier that throws if `_value` amount of tokens can't be transferred.
   */
  modifier canTransfer(address _sender, uint256 _value) {
    uint256 transferableTokensAmt = transferableTokens(_sender);
    require (_value <= transferableTokensAmt);
    // delete locks if all locks are cleared
    if (transferableTokensAmt == balanceOf(_sender) && getTokenLocksCount(_sender)>0) {
      delete locks[_sender];
    }
    _;
  }
}
