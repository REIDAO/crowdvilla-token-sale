//e.g.
//truffle migrate --reset --network live
//truffle migrate --reset --network rinkeby
//truffle migrate --reset --network ropsten
//truffle migrate  --reset --network ganache

//with ganache-cli
//truffle migrate --reset --network development
//truffle test test/1_crowdvilla_token_sale_goal_1_not_reached.js test/1_crowdvilla_token_sale_goal_1_reached.js test/1_crowdvilla_token_sale_goal_2_reached.js test/1_crowdvilla_token_sale_goal_3_reached.js

var fs = require("fs");
var path = require("path");

var bip39 = require("bip39");
var hdkey = require('ethereumjs-wallet/hdkey');
var ProviderEngine = require("web3-provider-engine");
var CacheSubprovider = require("web3-provider-engine/subproviders/cache.js");
var FiltersSubprovider = require('web3-provider-engine/subproviders/filters.js');
var WalletSubprovider = require('web3-provider-engine/subproviders/wallet.js');
var NonceSubprovider = require("web3-provider-engine/subproviders/nonce-tracker.js");
var FetchSubprovider = require("web3-provider-engine/subproviders/fetch.js");
var Web3 = require("web3");

var action = process.argv[2];
var providerInstance = new ProviderEngine();

if (action == "migrate") {
  var network = process.argv[5];
  if (network != undefined && network != "ganache") {
    var url = "https://rinkeby.infura.io/";
    var mnemonicSeeds = fs.readFileSync(path.join("../key", "mnemonic.test"), {encoding: "utf8"}).trim();

    if (network == "live") {
      url = "https://mainnet.infura.io/";
      mnemonicSeeds = fs.readFileSync(path.join("../key", "mnemonic.live"), {encoding: "utf8"}).trim();
    } else if (network == "ropsten") {
      url = "https://ropsten.infura.io/";
    }

    hdwallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(mnemonicSeeds));
    var mnemonicIndex = fs.readFileSync(path.join("../key", "index.key"), {encoding: "utf8"}).trim();
    if (mnemonicIndex == null) {
      mnemonicIndex = 0;
    }
    var infuraKey = fs.readFileSync(path.join("../key", "infura.key"), {encoding: "utf8"}).trim();
    url = url + infuraKey;

    var wallet_hdpath = "m/44'/60'/0'/";
    wallet = hdwallet.derivePath(wallet_hdpath + mnemonicIndex).getWallet();
    address = "0x" + wallet.getAddress().toString("hex");
    console.log("Deploying at " + url + " with " + address);

    providerInstance.addProvider(new CacheSubprovider());
    providerInstance.addProvider(new FiltersSubprovider());
    providerInstance.addProvider(new NonceSubprovider());
    providerInstance.addProvider(new WalletSubprovider(wallet, {}));
    providerInstance.addProvider(new FetchSubprovider({ rpcUrl: url }));
    providerInstance.start();
  }
}

var gasPrice = 41000000000;
var gasLimit = 5000000;

module.exports = {
  networks: {
    live: {
      provider: providerInstance,
      network_id: 1,
      gasPrice: gasPrice,
      gas: gasLimit
    },
    ropsten: {
      provider: providerInstance,
      network_id: 3,
      gasPrice: gasPrice,
      gas: gasLimit
    },
    rinkeby: {
      provider: providerInstance,
      network_id: 4,
      gasPrice: gasPrice,
      gas: gasLimit
    },
    ganache: {
      host: "localhost",
      port: 7545,
      network_id: 5777,
      gasPrice: gasPrice,
      gas: gasLimit
    },
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gasPrice: gasPrice,
      gas: gasLimit
    }
  },
  rpc: {
    // Use the default host and port when not using ropsten
    host: "localhost",
    port: 7545
  }
};
