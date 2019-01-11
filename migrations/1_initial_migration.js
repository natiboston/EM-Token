var Migrations = artifacts.require("Migrations");
var SEMToken = artifacts.require("EternalStorage");

module.exports = function(deployer, network, accounts) {
    deployer.deploy(Migrations, {from: accounts[0], gas: 4700000, gasPrice: 0});
    deployer.deploy(EternalStorage, {from:accounts[0], gas: 7000000, gasPrice:0});
};
