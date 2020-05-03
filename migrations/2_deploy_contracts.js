const OVRLand = artifacts.require("OVRLand")
const OVRToken = artifacts.require("OVRToken")
const TokenBuy = artifacts.require("TokenBuy")
const ICO = artifacts.require("ICO")
let ovrToken
let ovrLand
/// Real token addresses
/// daiToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
/// usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
/// usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
module.exports = async deployer => {
    deployer.deploy(OVRLand).then(_ovrLand => {
        ovrLand = _ovrLand.address
        console.log('Ovr land', ovrLand)
        return deployer.deploy(OVRToken)   
    }).then(_ovrToken => {
        ovrToken = _ovrToken.address
        console.log('Ovr token', ovrToken)
        return deployer.deploy(TokenBuy, 
            ovrToken,
            '0x6B175474E89094C44Da98b954EedeAC495271d0F',
            '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
            '0xdAC17F958D2ee523a2206206994597C13D831ec7',
        )
    }).then(tokenBuy => {
        console.log('Token buy', tokenBuy.address)
        return deployer.deploy(ICO, 
            ovrToken,
            ovrLand,
            String(10e18), // 10 OVR tokens as the initial required bid
        )
    }).then(ico => {
        console.log('ICO', ico.address)
    })
}
