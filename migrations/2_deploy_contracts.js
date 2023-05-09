var PharmaSupplyChain = artifacts.require("PharmaSupplyChain");

module.exports = function(deployer) {
  deployer.deploy(PharmaSupplyChain, { gas: 5000000 });
};
