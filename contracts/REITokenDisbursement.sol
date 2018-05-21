pragma solidity ^0.4.18;

import "./tokens/REIDAOMintableToken.sol";


contract REITokenDisbursement is Owners(true) {
    address public reiTokenAddr;
    address public wallet;
    REIDAOMintableToken reiToken;
    mapping (uint => bool) tokensReleased;
    event WaveReleased(uint wave, uint amount);

    /**
     * @dev initializes contract
     * @param _wallet address the address of REIDAO's wallet
     */
    function REITokenDisbursement(address _reiTokenAddr, address _wallet) public {
        reiTokenAddr = address(_reiTokenAddr);
        reiToken = REIDAOMintableToken(reiTokenAddr);
        wallet = _wallet;
    }

    /**
     * @dev disburses REI token allocated to REIDAO. this prevents multiple disbursements
     * of the same period.
     */
    function() public payable ownerOnly {
        if (msg.value == 0) {
            uint amount = 200000 * 10**reiToken.decimals();
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
                releaseWave(4, 150000 * 10**reiToken.decimals());
            }
        }
    }

    /**
     * @dev changes REIDAO wallet, can be called by owners.
     */
    function changeWallet(address _wallet) public ownerOnly {
        wallet = _wallet;
    }

    /**
     * @dev mints tokens and set flag upon minting.
     */
    function releaseWave(uint wave, uint amount) internal {
        assert(1 <= wave && wave <= 4);
        reiToken.mint(wallet, amount);
        tokensReleased[wave-1] = true;
        WaveReleased(wave, amount);
    }
}
