/* TEST DATA - START */
//accounts[0] = deployer, owner
//accounts[1] = tokenHolder
//accounts[2..4] = token holders

var loggingEnabled = false;

var CRVToken                = artifacts.require("./tokens/CRVToken.sol");
var CRPToken                = artifacts.require("./tokens/CRPToken.sol");
var CRPGeneration           = artifacts.require("./CRPGeneration.sol");
var AddressesEternalStorage = artifacts.require("./AddressesEternalStorage.sol");
var CRVTokenInstance; var CRPTokenInstance; var CRPGenerationInstance;
var AddressesEternalStorageInstance;

contract('All', function(accounts) {
  var owner = accounts[0];

  it("CRPGeneration - Deployment successful", function() {
    return CRPGeneration.deployed()
    .then(function(result) {
      CRPGenerationInstance = result;
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
  it("CRPToken - Deployment successful", function() {
    return CRPToken.deployed()
    .then(function(result) {
      CRPTokenInstance = result;
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
  it("Account #1 - Verifies CRP Token", function() {
    return CRPTokenInstance.balanceOf(accounts[1])
    .then(function(result) {
      assert.equal(result.valueOf(), 0 * Math.pow(10,8));
    })
    ;
  });
  it("CRVToken - Add Owners", function() {
    return CRVTokenInstance.addOwner(CRPGenerationInstance.address, {from:owner})
    ;
  });
  it("CRPToken - Add Owners", function() {
    return CRPTokenInstance.addOwner(CRPGenerationInstance.address, {from:owner})
    ;
  });
  it("Account #1 - Activate CRP Generation", function() {
    return web3.eth.sendTransaction({from:accounts[1], to:CRPGenerationInstance.address, value: 0, gas: 650000})
    ;
  });

  it("Account #1 - Verifies CRP Token balance after generation - 3000 CRP", function() {
    return CRPTokenInstance.balanceOf(accounts[1])
    .then(function(result) {
      assert.equal(result.valueOf(), 3000 * Math.pow(10,8));
    })
    ;
  });
  it("Crowdvilla NPO - Verifies CRP Token balance after generation - 5000 CRP", function() {
    return AddressesEternalStorageInstance.getEntry("CRPWalletCrowdvillaNpo")
    .then(function(result) {
      return CRPTokenInstance.balanceOf(result.valueOf())
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 5000 * Math.pow(10,8));
    })
    ;
  });
  it("Crowdvilla Ops Partner - Verifies CRP Token balance after generation - 1500 CRP", function() {
    return AddressesEternalStorageInstance.getEntry("CRPWalletCrowdvillaOps")
    .then(function(result) {
      return CRPTokenInstance.balanceOf(result.valueOf())
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 1500 * Math.pow(10,8));
    })
    ;
  });
  it("REIDAO - Verifies CRP Token balance after generation - 500 CRP", function() {
    return AddressesEternalStorageInstance.getEntry("CRPWalletReidao")
    .then(function(result) {
      return CRPTokenInstance.balanceOf(result.valueOf())
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
