var CrowdvillaTokenSale = artifacts.require("./CrowdvillaTokenSale.sol");
var REIToken = artifacts.require("./tokens/REIToken.sol");
var CRVToken = artifacts.require("./tokens/CRVToken.sol");
var Point = artifacts.require("./tokens/Point.sol");

var AddressesEternalStorage = artifacts.require("./registries/AddressesEternalStorage.sol");
var PointAllocationConfig = artifacts.require("./registries/PointAllocationConfig.sol");
var PointGenerationConfig = artifacts.require("./registries/PointGenerationConfig.sol");
var PointGeneration = artifacts.require("./PointGeneration.sol");

var reidaoWallet = "0x19BBe5157ffdf6Efa4C84810e7d2AE25832fF45D";
var crowdvillaWallet = "0x0c99d61b2019d48319C0339F2cE30A2C6f3F4430";
var opsAdmin = "0x0E7a6B35D6f10eE4805Af1E244dF3bF7819e1320";

module.exports = function(deployer, network, accounts) {
  deployer.deploy(CRVToken)
  .then(function() {
    return deployer.deploy(Point);
  })
  .then(function() {
    return deployer.deploy(REIToken, reidaoWallet);
  })
  .then(function() {
    return deployer.deploy(
      CrowdvillaTokenSale,
      50000, 125000, 250000,
      opsAdmin,
      crowdvillaWallet,
      reidaoWallet,
      CRVToken.address,
      Point.address,
      REIToken.address
      );
  })
  .then(function() {
    return deployer.deploy(PointGenerationConfig);
  })
  .then(function() {
    return deployer.deploy(PointAllocationConfig);
  })
  .then(function() {
    return deployer.deploy(AddressesEternalStorage);
  })
  .then(function() {
    AddressesEternalStorage.at(AddressesEternalStorage.address).addEntry("PointGenerationConfig", PointGenerationConfig.address);
  })
  .then(function() {
    AddressesEternalStorage.at(AddressesEternalStorage.address).addEntry("PointAllocationConfig", PointAllocationConfig.address);
  })
  .then(function() {
    AddressesEternalStorage.at(AddressesEternalStorage.address).addEntry("CRVToken", CRVToken.address);
  })
  .then(function() {
    AddressesEternalStorage.at(AddressesEternalStorage.address).addEntry("Point", Point.address);
  })
  .then(function() {
    AddressesEternalStorage.at(AddressesEternalStorage.address).addEntry("PointWalletCrowdvillaNpo", "0xae615F6d1c3F2e0Aa5279643853172163109332A");
  })
  .then(function() {
    AddressesEternalStorage.at(AddressesEternalStorage.address).addEntry("PointWalletCrowdvillaOps", "0x6aCAfca6D7BdAe682Bd868d3ee4E15608e03adE3");
  })
  .then(function() {
    AddressesEternalStorage.at(AddressesEternalStorage.address).addEntry("PointWalletReidao", reidaoWallet);
  })
  .then(function() {
    return deployer.deploy(PointGeneration, AddressesEternalStorage.address);
  })
  ;
};

/*
NOTE:
- For Testing, use stretch-goals 4, 7, 10
- For Live Deployment, use stretch-goals 50000, 125000, 250000
 */
