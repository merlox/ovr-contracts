const OVRLand = artifacts.require("OVRLand")
const OVRToken = artifacts.require("OVRToken")
const TokenBuy = artifacts.require("TokenBuy")
const ICO = artifacts.require("ICO")

module.exports = deployer => {
    deployer.deploy(OVRLand)
    deployer.deploy(ICO)
    deployer.deploy(OVRToken).then(ovrToken => {
        deployer.deploy(TokenBuy, ovrToken.address)
    })
}
