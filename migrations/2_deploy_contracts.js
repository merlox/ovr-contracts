const OVRLand = artifacts.require('OVRLand')
const OVRToken = artifacts.require('OVRToken')
const TokenBuy = artifacts.require('TokenBuy')
const ERC20 = artifacts.require('ERC20')
const ICO = artifacts.require('ICO')
let ovrToken
let ovrLand
let tokenBuy
let deployed = []
/// Real token addresses
/// daiToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
/// usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
/// usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
module.exports = async (deployer, network) => {
	if (network === 'ropsten') {
		deployer
			.deploy(ERC20)
			.then(token => {
				deployed.push(token.address)
				return deployer.deploy(ERC20)
			})
			.then(token => {
				deployed.push(token.address)
				return deployer.deploy(ERC20)
			})
			.then(token => {
				deployed.push(token.address)
				return deployer.deploy(OVRLand)
            })
            .then(_ovrLand => {
				deployed.push(_ovrLand.address)
                ovrLand = _ovrLand
				return deployer.deploy(OVRToken)
			})
			.then(async _ovrToken => {
				ovrToken = _ovrToken
				deployed.push(_ovrToken.address)
				ovrToken = _ovrToken
				return deployer.deploy(
                    TokenBuy,
					ovrToken.address,
					deployed[0],
					deployed[1],
					deployed[2],
				)
			})
			.then(_tokenBuy => {
				tokenBuy = _tokenBuy
				deployed.push(tokenBuy.address)
				return deployer.deploy(
                    ICO,
                    ovrToken.address,
                    ovrLand.address,
                    String(10e18), // 10 ovr as the initial land bid
                )
			}).then(async ico => {
				const accounts = await web3.eth.getAccounts()
				const amount = await ovrToken.balanceOf(accounts[0])
				await ovrToken.transfer(tokenBuy.address, amount)
				await tokenBuy.setTokenPrices(100, 10)
				console.log('DAI', deployed[0])
				console.log('Usdc', deployed[1])
				console.log('Tether', deployed[2])
				console.log('Ovr ERC721', deployed[3])
				console.log('Ovr ERC20', deployed[4])
				console.log('TokenBuy', deployed[5])
				console.log('ICO', ico.address)
			})
	} else {
		deployer
			.deploy(OVRLand)
			.then(_ovrLand => {
				ovrLand = _ovrLand.address
				console.log('Ovr land', ovrLand)
				return deployer.deploy(OVRToken)
			})
			.then(_ovrToken => {
				ovrToken = _ovrToken.address
				console.log('Ovr token', ovrToken)
				return deployer.deploy(
					TokenBuy,
					ovrToken,
					'0x6B175474E89094C44Da98b954EedeAC495271d0F',
					'0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
					'0xdAC17F958D2ee523a2206206994597C13D831ec7'
				)
			})
			.then(tokenBuy => {
				console.log('Token buy', tokenBuy.address)
				return deployer.deploy(
					ICO,
					ovrToken,
					ovrLand,
					String(10e18) // 10 OVR tokens as the initial required bid
				)
			})
			.then(ico => {
				console.log('ICO', ico.address)
			})
	}
}
