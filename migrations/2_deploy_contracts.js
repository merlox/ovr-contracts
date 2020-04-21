const OVRLand = artifacts.require("OVRLand")
const OVRToken = artifacts.require("OVRToken")
const TokenBuy = artifacts.require("TokenBuy")
const ICO = artifacts.require("ICO")

module.exports = async deployer => {
    const ovrToken = await deployer.deploy(OVRToken)
    console.log('Ovr token', ovrToken)
    deployer.deploy(OVRLand)
    await deployer.deploy(TokenBuy, ovrToken.address)
    deployer.deploy(ICO)
}
