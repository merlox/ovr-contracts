const OVRLand = artifacts.require('OVRLand')
const OVRToken = artifacts.require('OVRToken')
const TokenBuy = artifacts.require('TokenBuy')
const ERC20 = artifacts.require('ERC20')
const ICO = artifacts.require('ICO')
const ICOParticipate = artifacts.require('ICOParticipate')
let ovrToken
let ovrLand
let tokenBuy
let ico
let deployed = []
const perETH = 2000
const perUSD = 10

/// Real token addresses
/// daiToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
/// usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
/// usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
module.exports = async (deployer, network) => {
	if (network === 'mainnet') {
		deployer
			.deploy(OVRLand)
			.then(_ovrLand => {
				ovrLand = _ovrLand
				return deployer.deploy(OVRToken)
			})
			.then(async _ovrToken => {
				ovrToken = _ovrToken
				return deployer.deploy(
					TokenBuy,
					ovrToken.address,
					'0x6B175474E89094C44Da98b954EedeAC495271d0F',
					'0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
					'0xdAC17F958D2ee523a2206206994597C13D831ec7'
				)
			})
			.then(_tokenBuy => {
				tokenBuy = _tokenBuy
				return deployer.deploy(
					ICO,
					ovrToken.address,
					ovrLand.address,
					tokenBuy.address,
					String(10e18) // 10 ovr as the initial land bid
				)
			})
			.then(async _ico => {
				ico = _ico
				return deployer.deploy(
					ICOParticipate,
					ico.address,
				)
			})
			.then(async _icoParticipate => {
				const accounts = await web3.eth.getAccounts()
				const amount = await ovrToken.balanceOf(accounts[0])
				await ovrToken.transfer(tokenBuy.address, amount)
				await tokenBuy.setTokenPrices(perETH, perUSD)
				await ovrLand.addMinter(ico.address) // Make the ICO contract a ERC721 minter
				console.log('Setting up approved in the ICO contract...')
				await ico.setApproved(_icoParticipate.address)

				console.log('DAI', '0x6B175474E89094C44Da98b954EedeAC495271d0F')
				console.log('Usdc', '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48')
				console.log('Tether', '0xdAC17F958D2ee523a2206206994597C13D831ec7')
				console.log('Ovr ERC721', ovrLand.address)
				console.log('Ovr ERC20', ovrToken.address)
				console.log('TokenBuy', tokenBuy.address)
				console.log('ICO', ico.address)
				console.log('ICO Participate', _icoParticipate.address)
			})
	} else {
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
				deployed.push(_ovrToken.address)
				ovrToken = _ovrToken
				return deployer.deploy(
					TokenBuy,
					ovrToken.address,
					deployed[0],
					deployed[1],
					deployed[2]
				)
			})
			.then(_tokenBuy => {
				tokenBuy = _tokenBuy
				deployed.push(tokenBuy.address)
				return deployer.deploy(
					ICO,
					ovrToken.address,
					ovrLand.address,
					tokenBuy.address,
					String(10e18) // 10 ovr as the initial land bid
				)
			})
			.then(async _ico => {
				ico = _ico
				return deployer.deploy(
					ICOParticipate,
					ico.address,
				)
			})
			.then(async _icoParticipate => {
				const accounts = await web3.eth.getAccounts()
				const amount = await ovrToken.balanceOf(accounts[0])
				console.log('Transfering over tokens to the TokenBuy contract...')
				await ovrToken.transfer(tokenBuy.address, amount)
				console.log('Setting token prices in TokenBuy...')
				await tokenBuy.setTokenPrices(perETH, perUSD)
				console.log('Setting the ICO contract as the miner...')
				await ovrLand.addMinter(ico.address) // Make the ICO contract a ERC721 minter
				console.log('Setting auction duration to 10 minutes...')
				await ico.setAuctionLandDuration(600)
				console.log('Setting up approved in the ICO contract...')
				await ico.setApproved(_icoParticipate.address)
				
				console.log(`export const daiAddress = '${deployed[0]}';`)
				console.log(`export const usdcAddress = '${deployed[1]}';`)
				console.log(`export const tetherAddress = '${deployed[2]}';`)
				console.log(`export const ovr721Address = '${deployed[3]}';`)
				console.log(`export const ovrAddress = '${deployed[4]}';`)
				console.log(`export const tokenBuyAddress = '${deployed[5]}';`)
				console.log(`export const icoAddress = '${ico.address}';`)
				console.log(`export const icoParticipateAddress = '${_icoParticipate.address}';`)
			})
	}
}
