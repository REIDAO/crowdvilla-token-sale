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

var CrowdvillaTokenSale   = artifacts.require("./CrowdvillaTokenSale.sol");
var CRVToken              = artifacts.require("./tokens/CRVToken.sol");
var CRPToken              = artifacts.require("./tokens/CRPToken.sol");
var REIToken              = artifacts.require("./tokens/REIToken.sol")
var CrowdvillaTokenSaleInstance;
var CRVTokenInstance; var CRPTokenInstance; var REITokenInstance;

contract('All', function(accounts) {
  it("CrowdvillaTokenSale - Deployment successful", function() {
    return CrowdvillaTokenSale.deployed()
    .then(function(result) {
      CrowdvillaTokenSaleInstance = result;
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
  it("REIToken - Deployment successful", function() {
    return REIToken.deployed()
    .then(function(result) {
      REITokenInstance = result;
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

  var contributionInEther = 4;
  var contributionAmount = contributionInEther * Math.pow(10,18);
  var bonusMultiplier = 4;


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

  it("CrowdvillaTokenSale - Account #2 | Promised REI should be " + contributionInEther * 5 + " CRV", function() {
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

  it("CrowdvillaTokenSale - Account #3 | Promised REI should be " + contributionInEther * 5 + " CRV", function() {
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

  it("CrowdvillaTokenSale - Account #4 | Promised REI should be " + contributionInEther * 5 + " CRV", function() {
    return CrowdvillaTokenSaleInstance.getPromisedREITokenAmount(accounts[4])
    .then(function(result) {
      assert.equal(result.valueOf(), contributionInEther * 5 * Math.pow(10,8));
    })
    ;
  });

  var CRVmintedForContributors = [];

  it("CrowdvillaTokenSale - Account #2 | Promised CRV should be " + contributionInEther * (400 + (bonusMultiplier * 40)) + " CRV", function() {
    return CrowdvillaTokenSaleInstance.getPromisedCRVTokenAmount(accounts[2])
    .then(function(result) {
      CRVmintedForContributors.push(result.valueOf());
      assert.equal(result.valueOf(), contributionInEther * (400 + (bonusMultiplier * 40)) * Math.pow(10,8));
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #3 | Promised CRV should be " + contributionInEther * (400 + ((bonusMultiplier-1) * 40)) + " CRV", function() {
    return CrowdvillaTokenSaleInstance.getPromisedCRVTokenAmount(accounts[3])
    .then(function(result) {
      CRVmintedForContributors.push(result.valueOf());
      assert.equal(result.valueOf(), contributionInEther * (400 + ((bonusMultiplier-2) * 40)) * Math.pow(10,8));
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #4 | Promised CRV should be " + contributionInEther * 400 + " CRV", function() {
    return CrowdvillaTokenSaleInstance.getPromisedCRVTokenAmount(accounts[4])
    .then(function(result) {
      CRVmintedForContributors.push(result.valueOf());
      assert.equal(result.valueOf(), contributionInEther * (400 + (Math.max((bonusMultiplier-3),0) * 40)) * Math.pow(10,8));
    })
    ;
  });
  it("CrowdvillaTokenSale - Summary | MgmtFeeTokenAmount should be 1480 CRV", function() {
    return CrowdvillaTokenSaleInstance.getREIDAODistributionTokenAmount.call()
    .then(function(result) {
      var totalCRVMintedForContributors = CRVmintedForContributors.reduce(function(a, b) { return parseInt(a) + parseInt(b); }, 0);
      assert.equal(result.valueOf(), totalCRVMintedForContributors * 20/80);
    })
    ;
  });

  it("CrowdvillaTokenSale - State should be Ended", function() {
    return CrowdvillaTokenSaleInstance.state.call()
    .then(function(result) {
      assert.equal(result.valueOf(), 1);
    })
    ;
  });


  it("CrowdvillaTokenSale - Account #4 | Update Address - Accounts #9", function() {
    return CrowdvillaTokenSaleInstance.updateContributorAddress(accounts[4], accounts[9], {from:accounts[0]})
    ;
  });


  it("CrowdvillaTokenSale - State | Set to collection", function() {
    return CrowdvillaTokenSaleInstance.startCollection({from:accounts[0]})
    ;
  });
  it("CRVToken - Add Owners for minting", function() {
    return CRVTokenInstance.addOwner(CrowdvillaTokenSaleInstance.address, {from:accounts[0]})
    ;
  });
  it("CRPToken - Add Owners for minting", function() {
    return CRPTokenInstance.addOwner(CrowdvillaTokenSaleInstance.address, {from:accounts[0]})
    ;
  });
  it("REIToken - Add Owners for minting", function() {
    return REITokenInstance.addOwner(CrowdvillaTokenSaleInstance.address, {from:accounts[0]})
    ;
  });

  it("CRVToken - TotalSupply | Pre Collection", function() {
    return CRVTokenInstance.totalSupply.call().then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });
  it("CRPToken - TotalSupply | Pre Collection", function() {
    return CRPTokenInstance.totalSupply.call().then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });
  it("REIToken - TotalSupply | Pre Collection", function() {
    return REITokenInstance.totalSupply.call().then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });

  it("CrowdvillaTokenSale - Account #2 | CRV Balance Pre Collection", function() {
    return CRVTokenInstance.balanceOf(accounts[2]).then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #2 | CRP Balance Pre Collection", function() {
    return CRPTokenInstance.balanceOf(accounts[2]).then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #2 | Collection", function() {
    return web3.eth.sendTransaction({from:accounts[2], to:CrowdvillaTokenSaleInstance.address, value: 0, gas: 300000})
    ;
  });
  it("CrowdvillaTokenSale - Account #2 | CRV Balance Post Collection", function() {
    return CRVTokenInstance.balanceOf(accounts[2]).then(function(result) {
      assert.equal(result.valueOf(), CRVmintedForContributors[0]);
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #2 | CRP Balance Post Collection", function() {
    return CRPTokenInstance.balanceOf(accounts[2]).then(function(result) {
      assert.equal(result.valueOf(), CRVmintedForContributors[0]);
    })
    ;
  });

  it("CrowdvillaTokenSale - Account #3 | CRV Balance Pre Collection", function() {
    return CRVTokenInstance.balanceOf(accounts[3]).then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #3 | CRP Balance Pre Collection", function() {
    return CRPTokenInstance.balanceOf(accounts[3]).then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #3 | Collection", function() {
    return web3.eth.sendTransaction({from:accounts[3], to:CrowdvillaTokenSaleInstance.address, value: 0, gas: 300000})
    ;
  });
  it("CrowdvillaTokenSale - Account #3 | CRV Balance Post Collection", function() {
    return CRVTokenInstance.balanceOf(accounts[3]).then(function(result) {
      assert.equal(result.valueOf(), CRVmintedForContributors[1]);
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #3 | CRP Balance Post Collection", function() {
    return CRPTokenInstance.balanceOf(accounts[3]).then(function(result) {
      assert.equal(result.valueOf(), CRVmintedForContributors[1]);
    })
    ;
  });

  it("CrowdvillaTokenSale - Account #4 | CRV Balance Pre Collection", function() {
    return CRVTokenInstance.balanceOf(accounts[4]).then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #4 | CRP Balance Pre Collection", function() {
    return CRPTokenInstance.balanceOf(accounts[4]).then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #4 | Collection - Not Valid", function() {
    return web3.eth.sendTransaction({from:accounts[4], to:CrowdvillaTokenSaleInstance.address, value: 0, gas: 300000},
    function(error, result) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  });


  it("CrowdvillaTokenSale - Account #9 | CRV Balance Pre Collection", function() {
    return CRVTokenInstance.balanceOf(accounts[9]).then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #9 | CRP Balance Pre Collection", function() {
    return CRPTokenInstance.balanceOf(accounts[9]).then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #9 | Collection", function() {
    return web3.eth.sendTransaction({from:accounts[9], to:CrowdvillaTokenSaleInstance.address, value: 0, gas: 300000})
    ;
  });
  it("CrowdvillaTokenSale - Account #9 | CRV Balance Post Collection", function() {
    return CRVTokenInstance.balanceOf(accounts[9]).then(function(result) {
      assert.equal(result.valueOf(), CRVmintedForContributors[2]);
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #9 | CRP Balance Post Collection", function() {
    return CRPTokenInstance.balanceOf(accounts[9]).then(function(result) {
      assert.equal(result.valueOf(), CRVmintedForContributors[2]);
    })
    ;
  });

  it("CRVToken - TotalSupply | Post Collection", function() {
    return CRVTokenInstance.totalSupply.call().then(function(result) {
      var totalCRVMintedForContributors = CRVmintedForContributors.reduce(function(a, b) { return parseInt(a) + parseInt(b); }, 0);
      assert.equal(result.valueOf(), totalCRVMintedForContributors);
    })
    ;
  });
  it("CRPToken - TotalSupply | Post Collection", function() {
    return CRPTokenInstance.totalSupply.call().then(function(result) {
      var totalCRVMintedForContributors = CRVmintedForContributors.reduce(function(a, b) { return parseInt(a) + parseInt(b); }, 0);
      assert.equal(result.valueOf(), totalCRVMintedForContributors);
    })
    ;
  });
  it("REIToken - TotalSupply | Post Collection", function() {
    return REITokenInstance.totalSupply.call().then(function(result) {
      assert.equal(result.valueOf(), contributionInEther * 5 * 3 * Math.pow(10,8));
    })
    ;
  });


  it("CrowdvillaTokenSale - REIDAO | CRV Balance Pre Collection", function() {
    return CRVTokenInstance.balanceOf("0x19BBe5157ffdf6Efa4C84810e7d2AE25832fF45D").then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  });
  it("CRVToken - TotalSupply | Pre Collection", function() {
    return CRVTokenInstance.totalSupply.call().then(function(result) {
      var totalCRVMintedForContributors = CRVmintedForContributors.reduce(function(a, b) { return parseInt(a) + parseInt(b); }, 0);
      assert.equal(result.valueOf(), totalCRVMintedForContributors);
    })
    ;
  });
  it("CrowdvillaTokenSale - REIDAO | Collection", function() {
    return CrowdvillaTokenSaleInstance.collectREIDAODistribution({from:accounts[0]})
    ;
  });
  it("CrowdvillaTokenSale - REIDAO | CRV Balance Post Collection", function() {
    return CRVTokenInstance.balanceOf("0x19BBe5157ffdf6Efa4C84810e7d2AE25832fF45D").then(function(result) {
      var totalCRVMintedForContributors = CRVmintedForContributors.reduce(function(a, b) { return parseInt(a) + parseInt(b); }, 0);
      assert.equal(result.valueOf(), totalCRVMintedForContributors * 20/80);
    })
    ;
  });
  it("CRVToken - TotalSupply | Post Collection", function() {
    return CRVTokenInstance.totalSupply.call().then(function(result) {
      var totalCRVMintedForContributors = CRVmintedForContributors.reduce(function(a, b) { return parseInt(a) + parseInt(b); }, 0);
      assert.equal(result.valueOf(), totalCRVMintedForContributors * 100/80);
    })
    ;
  });

  it("CrowdvillaTokenSale - Account #9 | Send CRV Tokens - Not Valid due to trade not enabled yet", function() {
    return CRVTokenInstance.transfer(accounts[0], 1000, {from:accounts[9]})
    .catch(function(error) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  });
  it("CrowdvillaTokenSale - Account #9 | Trading Enabled", function() {
    return CRVTokenInstance.startTrading({from:accounts[0]})
    ;
  });
  it("CrowdvillaTokenSale - Account #9 | Send CRV Tokens - Valid due to trade already enabled", function() {
    return CRVTokenInstance.transfer(accounts[0], 1000, {from:accounts[9]})
    .then(function(result) {
      assert(true, result.valueOf());
      return CRVTokenInstance.balanceOf(accounts[9])
    })
    .then(function(result) {
      assert.equal(result.valueOf(), CRVmintedForContributors[2]-1000);
    })
    ;
  });

  it("CrowdvillaTokenSaleInstance - Update Sale End Block", function() {
    return CrowdvillaTokenSaleInstance.updateSaleEndBlock(5000000, {from:accounts[0]})
    ;
  });
  it("CrowdvillaTokenSaleInstance - End Token Sale", function() {
    return CrowdvillaTokenSaleInstance.endTokenSale.call({from:accounts[0]})
    ;
  });
  it("CrowdvillaTokenSale - State | Set to collection", function() {
    return CrowdvillaTokenSaleInstance.startCollection({from:accounts[0]})
    ;
  });
});

function getSum(total, num) {
    return total + num;
}

function log(msg)
{
  if (loggingEnabled)
    console.log(msg);
}
