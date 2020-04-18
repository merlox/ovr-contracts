const Migrations = artifacts.require('Migrations')
const OVRLand = artifacts.require('OVRLand')
const OVRToken = artifacts.require('OVRToken')
const TokenBuy = artifacts.require('TokenBuy')
const ICO = artifacts.require('ICO')

module.exports = function(deployer) {
  deployer.deploy(Migrations)
  deployer.deploy(OVRLand)
  deployer.deploy(OVRToken)
  deployer.deploy(TokenBuy)
  deployer.deploy(ICO)
};
