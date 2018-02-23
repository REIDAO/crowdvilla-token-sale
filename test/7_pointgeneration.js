/* TEST DATA - START */
//accounts[0] = deployer, owner
//accounts[1] = tokenHolder
//accounts[2..4] = token holders

var loggingEnabled = false;

var CRVToken                = artifacts.require("./tokens/CRVToken.sol");
var Point                = artifacts.require("./tokens/Point.sol");
var PointGeneration           = artifacts.require("./PointGeneration.sol");
var AddressesEternalStorage = artifacts.require("./AddressesEternalStorage.sol");
var CRVTokenInstance; var PointInstance; var PointGenerationInstance;
var AddressesEternalStorageInstance;

contract('All', function(accounts) {
  var owner = accounts[0];

  it("PointGeneration - Deployment successful", function() {
    return PointGeneration.deployed()
    .then(function(result) {
      PointGenerationInstance = result;
      assert.isNotNull(result.address, "Address is not empty: " + result.address);
    })
    ;
  });
  it("AddressesEternalStorage - Deployment successful", function() {
    return AddressesEternalStorage.deployed()
    .then(function(result) {
      AddressesEternalStorageInstance = result;
      assert.isNotNull(result.address, "Address is not empty: " + result.address);
    })
    ;
  });
  it("CRVToken - Deployment successful", function() {
    return CRVToken.deployed()
    .then(function(result) {
      CRVTokenInstance = result;
      assert.isNotNull(result.address, "Address is not empty: " + result.address);
    })
    ;
  });
  it("Point - Deployment successful", function() {
    return Point.deployed()
    .then(function(result) {
      PointInstance = result;
      assert.isNotNull(result.address, "Address is not empty: " + result.address);
    })
    ;
  });
  it("Account #1 - Minting 1000 CRV successful from Owner", function() {
    return CRVTokenInstance.mint(accounts[1], 1000 * Math.pow(10,8), {from:owner})
    .then(function(result) {
      return CRVTokenInstance.balanceOf(accounts[1])
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 1000 * Math.pow(10,8));
    })
    ;
  });
  it("Account #1 - Verifies CRV transferable tokens before generation", function() {
    return CRVTokenInstance.transferableTokens(accounts[1])
    .then(function(result) {
      assert.equal(result.valueOf(), 1000 * Math.pow(10,8));
    })
    ;
  });
  it("Account #1 - Verifies Point balance before generation", function() {
    return PointInstance.balanceOf(accounts[1])
    .then(function(result) {
      assert.equal(result.valueOf(), 0 * Math.pow(10,8));
    })
    ;
  });
  it("CRVToken - Add Owners", function() {
    return CRVTokenInstance.addOwner(PointGenerationInstance.address, {from:owner})
    ;
  });
  it("Point - Add Owners", function() {
    return PointInstance.addOwner(PointGenerationInstance.address, {from:owner})
    ;
  });
  it("Account #1 - Activate Point Generation", function() {
    return web3.eth.sendTransaction({from:accounts[1], to:PointGenerationInstance.address, value: 0, gas: 650000})
    ;
  });

  it("Account #1 - Verifies CRV not transferable tokens after generation", function() {
    return CRVTokenInstance.transferableTokens(accounts[1])
    .then(function(result) {
      assert.equal(result.valueOf(), 0 * Math.pow(10,8));
    })
    ;
  });

  it("Account #1 - Verifies Point balance after generation - 3000 Point", function() {
    return PointInstance.balanceOf(accounts[1])
    .then(function(result) {
      assert.equal(result.valueOf(), 3000 * Math.pow(10,8));
    })
    ;
  });
  it("Account #1 - Verifies Point 50% transferable after generation - 1500 Point", function() {
    return PointInstance.transferableTokens(accounts[1])
    .then(function(result) {
      assert.equal(result.valueOf(), 1500 * Math.pow(10,8));
    })
    ;
  });
  it("Crowdvilla NPO - Verifies Point balance after generation - 5000 Point", function() {
    return AddressesEternalStorageInstance.getEntry("PointWalletCrowdvillaNpo")
    .then(function(result) {
      return PointInstance.balanceOf(result.valueOf())
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 5000 * Math.pow(10,8));
    })
    ;
  });
  it("Crowdvilla Ops Partner - Verifies Point balance after generation - 1500 Point", function() {
    return AddressesEternalStorageInstance.getEntry("PointWalletCrowdvillaOps")
    .then(function(result) {
      return PointInstance.balanceOf(result.valueOf())
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 1500 * Math.pow(10,8));
    })
    ;
  });
  it("REIDAO - Verifies Point balance after generation - 500 Point", function() {
    return AddressesEternalStorageInstance.getEntry("PointWalletReidao")
    .then(function(result) {
      return PointInstance.balanceOf(result.valueOf())
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 500 * Math.pow(10,8));
    })
    ;
  });
});

function log(msg)
{
  if (loggingEnabled)
    console.log(msg);
}
