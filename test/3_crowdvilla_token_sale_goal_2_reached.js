/* TEST DATA - START */
//testing for emergency refund. To be updated with multisig testing for setStateEmergency
//Run with `testrpc -a 25`
//accounts[0] = deployer, owner
//accounts[1] = opsAdmin
//accounts[2] = whitelisted and earlyRegistrant
//accounts[3] = whitelisted and not earlyRegistrant
//accounts[4] = not whitelisted (doesn't matter if it is earlyRegistrant or not)
//accounts[5] = ReferralCode CODE1 Wallet
//accounts[6] = ReferralCode CODE2 Wallet

var loggingEnabled = false;

var CrowdvillaTokenSale            = artifacts.require("./CrowdvillaTokenSale.sol");
var CrowdvillaTokenSaleInstance;

var crvPerETH = 4000;
var crvBonusRate = crvPerETH * 10/100; //10%
var mgmtFee = 20;

contract('All', function(accounts) {
  it("CrowdvillaTokenSale - Deployment successful", function() {
    return CrowdvillaTokenSale.deployed()
    .then(function(result) {
      CrowdvillaTokenSaleInstance = result;
      assert.isNotNull(result.address, "Address is not empty: " + result.address);
    })
    ;
  });

  it("CrowdvillaTokenSale - State should be Initial", function() {
    return CrowdvillaTokenSaleInstance.state.call()
    .then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });

  it("CrowdvillaTokenSale - Total ReferralCode Multisig Wallet should be 0", function() {
    return CrowdvillaTokenSaleInstance.totalReferralMultisig.call()
    .then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });

  it("CrowdvillaTokenSale - Updating opsAdmin", function() {
    return CrowdvillaTokenSaleInstance.opsAdmin.call()
    .then(function (result) {
      log("Current opsAdmin: " + result);
    })
    .then(function (result) {
      return CrowdvillaTokenSaleInstance.updateOpsAdmin(accounts[1])
    })
    .then(function(result) {
      return CrowdvillaTokenSaleInstance.opsAdmin.call()
    })
    .then(function (result) {
      log("Current opsAdmin: " + result);
    })
    ;
  });

  it("CrowdvillaTokenSale - Register ReferralCode CODE1 Wallet", function() {
    return CrowdvillaTokenSaleInstance.registerReferralMultisig("CODE1", accounts[5], {from:accounts[1]})
    .then(function(result) {
      return CrowdvillaTokenSaleInstance.totalReferralMultisig.call()
      .then(function(result) {
        assert.equal(result.valueOf(), 1);
      })
      ;
    })
    ;
  });

  it("CrowdvillaTokenSale - TotalFund should be 0 ETH", function() {
    return CrowdvillaTokenSaleInstance.totalFund.call()
    .then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });

  var contributionInEther = 3;
  var contributionAmount = contributionInEther * Math.pow(10,18);
  var bonusMultiplier = 3;


  //Account #2 with referralCode and is early registrant
  it("CrowdvillaTokenSale - Account #2 | Whitelist with referralCode and earlyRegistrant", function() {
    return CrowdvillaTokenSaleInstance.addToWhitelist(accounts[2], true, "CODE1", {from:accounts[1]})
    ;
  });

  it("CrowdvillaTokenSale - Account #2 | Sends " + contributionInEther + " ETH", function() {
    return web3.eth.sendTransaction({from:accounts[2], to:CrowdvillaTokenSaleInstance.address, value: contributionAmount, gas: 300000})
    ;
  });


  it("CrowdvillaTokenSale - Account #2 | TotalFund should be " + contributionInEther + " ETH", function() {
    return CrowdvillaTokenSaleInstance.totalFund.call()
    .then(function(result) {
      assert.equal(result.valueOf(), contributionAmount);
    })
    ;
  });

  it("CrowdvillaTokenSale - Account #2 | Promised REI should be " + contributionInEther * 5 + " REI", function() {
    return CrowdvillaTokenSaleInstance.getPromisedREITokenAmount(accounts[2])
    .then(function(result) {
      assert.equal(result.valueOf(), contributionInEther * 5 * Math.pow(10,8));
    })
    ;
  });


  //Account #3 with referralCode but is not early registrant
  it("CrowdvillaTokenSale - Account #3 | Whitelist with referralCode and not earlyRegistrant", function() {
    return CrowdvillaTokenSaleInstance.addToWhitelist(accounts[3], false, "CODE1", {from:accounts[1]})
    ;
  });

  it("CrowdvillaTokenSale - Account #3 | Sends " + contributionInEther + " ETH", function() {
    return web3.eth.sendTransaction({from:accounts[3], to:CrowdvillaTokenSaleInstance.address, value: contributionAmount, gas: 300000})
    ;
  });

  it("CrowdvillaTokenSale - Account #3 | TotalFund should be " + contributionInEther * 2 + " ETH", function() {
    return CrowdvillaTokenSaleInstance.totalFund.call()
    .then(function(result) {
      assert.equal(result.valueOf(), contributionAmount * 2);
    })
    ;
  });

  it("CrowdvillaTokenSale - Account #3 | Promised REI should be " + contributionInEther * 5 + " REI", function() {
    return CrowdvillaTokenSaleInstance.getPromisedREITokenAmount(accounts[3])
    .then(function(result) {
      assert.equal(result.valueOf(), contributionInEther * 5 * Math.pow(10,8));
    })
    ;
  });


  //Account #4 with no referralCode
  it("CrowdvillaTokenSale - Account #4 | Whitelist without referralCode", function() {
    return CrowdvillaTokenSaleInstance.addToWhitelist(accounts[4], false, "", {from:accounts[1]})
    ;
  });

  it("CrowdvillaTokenSale - Account #4 | Sends " + contributionInEther + " ETH", function() {
    return web3.eth.sendTransaction({from:accounts[4], to:CrowdvillaTokenSaleInstance.address, value: contributionAmount, gas: 300000})
    ;
  });

  it("CrowdvillaTokenSale - Account #4 | TotalFund should be " + contributionInEther * 3 + " ETH", function() {
    return CrowdvillaTokenSaleInstance.totalFund.call()
    .then(function(result) {
      assert.equal(result.valueOf(), contributionAmount * 3);
    })
    ;
  });

  it("CrowdvillaTokenSale - Account #4 | Promised REI should be " + contributionInEther * 5 + " REI", function() {
    return CrowdvillaTokenSaleInstance.getPromisedREITokenAmount(accounts[4])
    .then(function(result) {
      assert.equal(result.valueOf(), contributionInEther * 5 * Math.pow(10,8));
    })
    ;
  });

  var CRVmintedForContributors = [];

  it("CrowdvillaTokenSale - Account #2 | Promised CRV should be " + contributionInEther * (crvPerETH + (bonusMultiplier * crvBonusRate)) + " CRV", function() {
    return CrowdvillaTokenSaleInstance.getPromisedCRVTokenAmount(accounts[2])
    .then(function(result) {
      CRVmintedForContributors.push(result.valueOf());
      assert.equal(result.valueOf(), contributionInEther * (crvPerETH + (bonusMultiplier * crvBonusRate)) * Math.pow(10,8));
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #3 | Promised CRV should be " + contributionInEther * (crvPerETH + ((bonusMultiplier-1) * crvBonusRate)) + " CRV", function() {
    return CrowdvillaTokenSaleInstance.getPromisedCRVTokenAmount(accounts[3])
    .then(function(result) {
      CRVmintedForContributors.push(result.valueOf());
      assert.equal(result.valueOf(), contributionInEther * (crvPerETH + ((bonusMultiplier-1) * crvBonusRate)) * Math.pow(10,8));
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #4 | Promised CRV should be " + contributionInEther * (crvPerETH + (Math.max((bonusMultiplier-2),0) * crvBonusRate)) + " CRV", function() {
    return CrowdvillaTokenSaleInstance.getPromisedCRVTokenAmount(accounts[4])
    .then(function(result) {
      CRVmintedForContributors.push(result.valueOf());
      assert.equal(result.valueOf(), contributionInEther * (crvPerETH + (Math.max((bonusMultiplier-2),0) * crvBonusRate)) * Math.pow(10,8));
    })
    ;
  });
  it("CrowdvillaTokenSale - Summary | MgmtFeeTokenAmount should be 10800 CRV", function() {
    return CrowdvillaTokenSaleInstance.getREIDAODistributionTokenAmount.call()
    .then(function(result) {
      var totalCRVMintedForContributors = CRVmintedForContributors.reduce(function(a, b) { return parseInt(a) + parseInt(b); }, 0);
      assert.equal(result.valueOf(), totalCRVMintedForContributors * mgmtFee/(100-mgmtFee));
    })
    ;
  });
});

function log(msg)
{
  if (loggingEnabled)
    console.log(msg);
}
