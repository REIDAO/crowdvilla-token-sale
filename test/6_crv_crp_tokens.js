/* TEST DATA - START */
//accounts[0] = deployer, owner
//accounts[1] = nonOwner
//accounts[2..5] = token holders

var loggingEnabled = false;

var CRVToken              = artifacts.require("./tokens/CRVToken.sol");
var CRPToken              = artifacts.require("./tokens/CRPToken.sol");
var CRVTokenInstance; var CRPTokenInstance;

contract('All', function(accounts) {
  var owner = accounts[0];
  var nonOwner = accounts[1];
  var nowTime = new Date().getTime()/1000 | 0;
  var lockedTokensFutureTimeout = nowTime + 100;
  var secondsAdvance = 5;
  var lockedTokensSlowFutureTimeout = nowTime + secondsAdvance;
  console.log("nowTime                       : " + nowTime);
  console.log("lockedTokensFutureTimeout     : " + lockedTokensFutureTimeout);
  console.log("lockedTokensSlowFutureTimeout : " + lockedTokensSlowFutureTimeout);

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
  it("Account #2 - Minting 1000 CRV failed from non-Owner", function() {
    return CRVTokenInstance.mint(accounts[2], 1000 * Math.pow(10,8), {from:nonOwner})
    .catch(function(error) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  });
  it("Account #2 - Minting 1000 CRV successful from Owner", function() {
    return CRVTokenInstance.mint(accounts[2], 1000 * Math.pow(10,8), {from:owner})
    .then(function(result) {
      return CRVTokenInstance.balanceOf(accounts[2])
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 1000 * Math.pow(10,8));
    })
    ;
  });
  it("Account #2 - Transfer failed due to trade feature not enabled yet", function() {
    return CRVTokenInstance.transfer(accounts[2], 300 * Math.pow(10,8), {from:accounts[2]})
    .catch(function(error) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  });
  it("CRVToken - Trade feature has not started", function() {
    return CRVTokenInstance.tradingStarted()
    .then(function (result) {
      assert.isFalse(result.valueOf(), "Trading has not started");
    })
    ;
  });
  it("CRVToken - Trade feature enabling failed from non-Owner", function() {
    return CRVTokenInstance.startTrading({from:nonOwner})
    .catch(function(error) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  });
  it("CRVToken - Trade feature enabling successful from Owner", function() {
    return CRVTokenInstance.startTrading({from:owner})
    .then(function(result) {
      return CRVTokenInstance.tradingStarted()
    })
    .then(function (result) {
      assert.isTrue(result.valueOf(), "Trading has started");
    })
    ;
  });
  it("Account #2 - Transfer successful due to trade feature is enabled", function() {
    return CRVTokenInstance.transfer(accounts[3], 300 * Math.pow(10,8), {from:accounts[2]})
    .then(function(result) {
      return CRVTokenInstance.balanceOf(accounts[2])
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 700 * Math.pow(10,8));
    })
    ;
  });
  it("CRVToken - Stop Minting failed from non-Owner", function() {
    return CRVTokenInstance.finishMinting({from:nonOwner})
    .catch(function(error) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  });
  it("CRVToken - Stop Minting successful from Owner", function() {
    return CRVTokenInstance.finishMinting({from:owner})
    .then(function(result) {
      return CRVTokenInstance.mintingFinished()
    })
    .then(function (result) {
      assert.isTrue(result.valueOf(), "Minting has finished");
    })
    ;
  });
  it("CRVToken - Start Minting failed from non-Owner", function() {
    return CRVTokenInstance.startMinting({from:nonOwner})
    .catch(function(error) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  });
  it("CRVToken - Start Minting successful from Owner", function() {
    return CRVTokenInstance.startMinting({from:owner})
    .then(function(result) {
      return CRVTokenInstance.mintingFinished()
    })
    .then(function (result) {
      assert.isFalse(result.valueOf(), "Minting has started");
    })
    ;
  });
  it("Account #2 - Minting 300 CRV successful from Owner", function() {
    return CRVTokenInstance.mint(accounts[2], 300 * Math.pow(10,8), {from:owner})
    .then(function(result) {
      return CRVTokenInstance.balanceOf(accounts[2])
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 1000 * Math.pow(10,8));
    })
    ;
  });
  it("Account #2 - Has no locked tokens", function() {
    return CRVTokenInstance.getLockedTokens(accounts[2])
    .then(function(result) {
      assert.equal(result.valueOf(), 0);
    })
    ;
  })
  ;
  it("Account #2 - Lock tokens failed from non-Owner", function() {
    return CRVTokenInstance.lockTokens(accounts[2], 10 * Math.pow(10,8), lockedTokensFutureTimeout, {from:nonOwner})
    .catch(function(error) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  });
  it("Account #2 - Lock tokens successful from Owner", function() {
    return CRVTokenInstance.lockTokens(accounts[2], 10 * Math.pow(10,8), lockedTokensFutureTimeout, {from:owner})
    .then(function(result) {
      return CRVTokenInstance.getLockedTokens(accounts[2])
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 10 * Math.pow(10,8));
    })
    ;
  });
  it("Account #2 - Not hosted wallet yet", function() {
    return CRVTokenInstance.hostedWallets(accounts[2])
    .then(function(result) {
      assert.isFalse(result.valueOf(), "Is not hosted wallet");
    })
    ;
  });
  it("Account #2 - Burn tokens failed due to not being hosted wallet", function() {
    return CRVTokenInstance.burn(1 * Math.pow(10,8), {from:accounts[2]})
    .catch(function(error) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  });
  it("Account #2 - Add hosted wallet failed from non-Owner", function() {
    return CRVTokenInstance.addHostedWallet(accounts[2], {from:nonOwner})
    .catch(function(error) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  });
  it("Account #2 - Add hosted wallet successful from Owner", function() {
    return CRVTokenInstance.addHostedWallet(accounts[2], {from:owner})
    .then(function(result) {
      return CRVTokenInstance.hostedWallets(accounts[2]);
    })
    .then(function(result) {
      assert.isTrue(result.valueOf(), "Is now hosted wallet");
    })
    ;
  });
  it("Account #2 - Burn tokens successful due to being hosted wallet", function() {
    return CRVTokenInstance.burn(1 * Math.pow(10,8), {from:accounts[2]})
    .then(function(result) {
      return CRVTokenInstance.balanceOf(accounts[2])
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 999 * Math.pow(10,8));
    })
    ;
  });
  it("Account #2 - Remove hosted wallet failed from non-Owner", function() {
    return CRVTokenInstance.removeHostedWallet(accounts[2], {from:nonOwner})
    .catch(function(error) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  });
  it("Account #2 - Remove hosted wallet successful from Owner", function() {
    return CRVTokenInstance.removeHostedWallet(accounts[2], {from:owner})
    .then(function(result) {
      return CRVTokenInstance.hostedWallets(accounts[2]);
    })
    .then(function(result) {
      assert.isFalse(result.valueOf(), "Is not hosted wallet");
    })
    ;
  });
  it("Account #4 - Balance check before minting", function() {
    return CRVTokenInstance.balanceOf(accounts[4])
    .then(function(result) {
      assert.equal(result.valueOf(), 0 * Math.pow(10,8));
    });
  })
  it("Account #4 - Mint and Lock tokens failed from non-Owner", function() {
    return CRVTokenInstance.mintAndLockTokens(accounts[4], 10 * Math.pow(10,8), lockedTokensFutureTimeout, {from:nonOwner})
    .catch(function(error) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  });
  it("Account #4 - Mint and Lock tokens successful from Owner", function() {
    return CRVTokenInstance.mintAndLockTokens(accounts[4], 10 * Math.pow(10,8), lockedTokensFutureTimeout, {from:owner})
    .then(function(result) {
      return CRVTokenInstance.getLockedTokens(accounts[4])
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 10 * Math.pow(10,8));
    })
    ;
  });
  it("Account #4 - Balance check after minting", function() {
    return CRVTokenInstance.balanceOf(accounts[4])
    .then(function(result) {
      assert.equal(result.valueOf(), 10 * Math.pow(10,8));
    });
  })
  it("Account #4 - Transfer lockable tokens should fail", function() {
    return CRVTokenInstance.transfer(accounts[5], 2 * Math.pow(10,8), {from:accounts[4]})
    .catch(function(error) {
      assert(true, error.toString().indexOf("VM Exception")>-1);
    })
    ;
  })
  it("Account #5 - Mint tokens successful from Owner", function() {
    return CRVTokenInstance.mintAndLockTokens(accounts[5], 10 * Math.pow(10,8), lockedTokensSlowFutureTimeout, {from:owner})
    .then(function(result) {
      return CRVTokenInstance.getLockedTokens(accounts[5])
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 10 * Math.pow(10,8));
    })
    ;
  });
  it("Account #5 - Balance check after minting", function() {
    return CRVTokenInstance.balanceOf(accounts[5])
    .then(function(result) {
      assert.equal(result.valueOf(), 10 * Math.pow(10,8));
    });
  })
  it("Account #5 - Transfer tokens should be OK", function() {
    setTimeout(function() {
      return CRVTokenInstance.transfer(accounts[7], 10 * Math.pow(10,8), {from:accounts[5]})
      .then(function(result) {
        return CRVTokenInstance.balanceOf(accounts[5])
      })
      .then(function(result) {
        assert.equal(result.valueOf(), 0 * Math.pow(10,8));
      })
      ;
    }, (secondsAdvance+1) * 1000);
  })
  it("Account #6 - Mint tokens successful from Owner", function() {
    return CRVTokenInstance.mint(accounts[6], 10 * Math.pow(10,8), {from:owner})
    .then(function(result) {
      return CRVTokenInstance.getLockedTokens(accounts[6])
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 0 * Math.pow(10,8));
    })
    ;
  });
  it("Account #6 - Balance check after minting", function() {
    return CRVTokenInstance.balanceOf(accounts[6])
    .then(function(result) {
      assert.equal(result.valueOf(), 10 * Math.pow(10,8));
    });
  })
  it("Account #6 - Transfer tokens should be OK", function() {
    return CRVTokenInstance.transfer(accounts[7], 2 * Math.pow(10,8), {from:accounts[6]})
    .then(function(result) {
      return CRVTokenInstance.balanceOf(accounts[6])
    })
    .then(function(result) {
      assert.equal(result.valueOf(), 8 * Math.pow(10,8));
    })
    ;
  })
});

function log(msg)
{
  if (loggingEnabled)
    console.log(msg);
}
