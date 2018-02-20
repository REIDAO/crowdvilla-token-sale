pragma solidity ^0.4.18;

import "./REIDAOMintableToken.sol";

contract REIToken is REIDAOMintableToken {
  string public name = "REI Token";
  string public symbol = "REI";

  address public wallet;
  mapping (uint => bool) tokensReleased;
  event WaveReleased(uint wave, uint amount);

  /**
   * @dev initializes contract
   * @param _wallet address the address of REIDAO's wallet
   */
  function REIToken(address _wallet) public {
    wallet = _wallet;
  }

  /**
   * @dev changes REIDAO wallet, can be called by owners.
   */
  function changeWallet(address _wallet) public ownerOnly {
    wallet = _wallet;
  }

  /**
   * @dev disburses REI token allocated to REIDAO. this prevents multiple disbursements
   *   of the same period.
   */
  function disburseToREIDAO() public ownerOnly {
    uint amount = 200000 * 10**decimals;
    if (!tokensReleased[0]) {
      //for WAVE 1 - immediate
      releaseWave(1, amount);
    } else if (block.timestamp >= 1577836800 && !tokensReleased[1]) {
      //for WAVE 2 - after 01/01/2020 @ 12:00am (UTC)
      releaseWave(2, amount);
    } else if (block.timestamp >= 1609459200 && !tokensReleased[2]) {
      //for WAVE 3 - after 01/01/2021 @ 12:00am (UTC)
      releaseWave(3, amount);
    } else if (block.timestamp >= 1640995200 && !tokensReleased[3]) {
      //for WAVE 4 - after 01/01/2022 @ 12:00am (UTC)
      releaseWave(4, 150000 * 10**decimals);
    }
  }

  function releaseWave(uint wave, uint amount) internal {
    assert(1 <= wave && wave <=4);
    internalMint(wallet, amount);
    tokensReleased[wave-1] = true;
    WaveReleased(wave, amount);
  }
}
