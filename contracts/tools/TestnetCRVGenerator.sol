pragma solidity ^0.4.18;

import "./math/SafeMath.sol";
import "./ownership/Owners.sol";
import "./tokens/REIDAOMintableBurnableLockableToken.sol";


contract TestnetCRVGenerator is Owners(true) {
    using SafeMath for uint256;

    enum State { Active, Inactive }
    State public state;

    uint public crvPerEth;
    address public crvTokenAddr;
    address public pointAddr;
    REIDAOMintableBurnableLockableToken crvToken;
    REIDAOMintableBurnableLockableToken point;

    function TestnetCRVGenerator(address _crvTokenAddr, address _pointAddr) public {
        state = State.Active;
        crvTokenAddr = address(_crvTokenAddr);
        crvToken = REIDAOMintableBurnableLockableToken(crvTokenAddr);
        pointAddr = address(_pointAddr);
        point = REIDAOMintableBurnableLockableToken(pointAddr);
        crvPerEth = 4000 * (10**crvToken.decimals());
    }
    // public - START ------------------------------------------------------------

    /**
    *@notice this function is the fallback function.
    *this function is a payable funciton that receive the ehter sent by the msg.sender and give the crv token back.
    *since the msg.value is in unit of wei, we convert the result by divided it by 10**18.
    *@dev this is a public funciton, and all msg.senders can call this function
    */
    function () public payable {
        require(state == State.Active);
        uint amount = msg.value.mul(crvPerEth).div(10**18);
        crvToken.mint(msg.sender, amount);
        point.mint(msg.sender, amount);
    }
    // public - END --------------------------------------------------------------

    // ownerOnly - START ---------------------------------------------------------
    /**
    * @notice this function allows owner to send all of this contract's ether to the specified recipient
    * @dev only owners of this contract can call this function.
    * @param _recepient address is the address of recipient's wallet
    */
    function sendAllEth(address _recepient) public ownerOnly {
        return _recepient.transfer(address(this).balance);
    }

    /**
    * @notice this function toggles the state of the token exchange service.
    * @dev only owners of this contract can call this function.
    */
    function changeState() public ownerOnly {
        if (state == State.Active) {
            state = State.Inactive;
        } else {
            state = State.Active;
        }
    }
    // ownerOnly - END -----------------------------------------------------------
}
