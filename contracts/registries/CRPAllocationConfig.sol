pragma solidity ^0.4.18;

import "../ownership/Owners.sol";

contract CRPAllocationConfig is Owners(true) {

  mapping(bytes32 => uint) public configs;

  event CRPAllocationConfigSet(uint allocationTokenHolder, uint allocationCrowdvillaNpo, uint allocationCrowdvillaOps, uint allocationReidao);

  /**
   * @dev initialized contract with default values
   */
  function CRPAllocationConfig() public {
    addConfig(30, 50, 15, 5);
  }

  /**
   * @dev adds or updates config
   * @param _allocTokenHolder uint the amount allocated for token holder
   * @param _allocCrowdvillaNpo uint the amount allocated for Crowdvilla NPO
   * @param _allocCrowdvillaOps uint the amount allocated for Crowdvilla Ops
   * @param _allocReidao uint the amount allocated for REIDAO
   */
  function addConfig(uint _allocTokenHolder, uint _allocCrowdvillaNpo, uint _allocCrowdvillaOps, uint _allocReidao) public ownerOnly {
    assert (100 == (_allocTokenHolder + _allocCrowdvillaNpo + _allocCrowdvillaOps + _allocReidao));
    configs["tokenHolder"] = _allocTokenHolder;
    configs["crowdvillaNpo"] = _allocCrowdvillaNpo;
    configs["crowdvillaOps"] = _allocCrowdvillaOps;
    configs["reidao"] = _allocReidao;
    CRPAllocationConfigSet(_allocTokenHolder, _allocCrowdvillaNpo, _allocCrowdvillaOps, _allocReidao);
  }

  /**
   * @dev retrieves config
   * @param _party bytes32 the party to be retrieved
   * @return the amount allocated for `_party`
   */
  function getConfig(bytes32 _party) public view returns (uint) {
    return configs[_party];
  }

}
