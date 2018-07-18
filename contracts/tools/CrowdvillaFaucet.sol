pragma solidity ^0.4.18;

import "./math/SafeMath.sol";
import "./ownership/Owners.sol";
import "./tokens/REIDAOMintableBurnableLockableToken.sol";
import "./registries/AddressesEternalStorage.sol";
import "./registries/PointAllocationConfig.sol";
import "./registries/PointGenerationConfig.sol";


contract CrowdvillaFaucet is Owners(true) {

    using SafeMath for uint256;

    enum State { Active, Inactive }
    State public state;
    REIDAOMintableBurnableLockableToken crvToken;
    REIDAOMintableBurnableLockableToken point;

    AddressesEternalStorage eternalStorage;
    PointGenerationConfig pointGenerationConfig;
    PointAllocationConfig pointAllocationConfig;
    uint public faucetAmount = 10000000000;

    function CrowdvillaFaucet(AddressesEternalStorage _eternalStorage) public {
        state = State.Active;
        addOwner(0x5cf3a67a0607a8385260bda28d914e3e49efc688);
        eternalStorage = _eternalStorage;
        crvToken = REIDAOMintableBurnableLockableToken(eternalStorage.getEntry("CRVToken"));
        point = REIDAOMintableBurnableLockableToken(eternalStorage.getEntry("Point"));
    }

    function distribute(address requester) external ownerOnly {
        require(state == State.Active);
        crvToken.transfer(requester, faucetAmount);
        point.transfer(requester, faucetAmount);
    }

    function activateState() public ownerOnly {
        state = State.Active;
    }

    function inactivateState() public ownerOnly {
        state = State.Inactive;
    }
}
