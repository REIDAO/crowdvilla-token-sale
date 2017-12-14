var CrowdvillaTokenSale = artifacts.require("./CrowdvillaTokenSale.sol");
var REIToken = artifacts.require("./tokens/REIToken.sol");
var CRVToken = artifacts.require("./tokens/CRVToken.sol");
var CRPToken = artifacts.require("./tokens/CRPToken.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(CRVToken)
  .then(function() {
    return deployer.deploy(CRPToken);
  })
  .then(function() {
    return deployer.deploy(REIToken);
  })
  .then(function() {
    return deployer.deploy(
      CrowdvillaTokenSale,
      100000, 250000, 500000,
      "0x0E7a6B35D6f10eE4805Af1E244dF3bF7819e1320",
      "0x0c99d61b2019d48319C0339F2cE30A2C6f3F4430",
      CRVToken.address,
      CRPToken.address,
      REIToken.address
      );
  });
};
