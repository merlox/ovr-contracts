const assert = require('assert')
const TokenBuy = artifacts.require('TokenBuy')
const OVRToken = artifacts.require('OVRToken')
let tokenBuy = {}
let ovrToken = {}
const priceToSetEth = 100
const priceToSetUsd = 10

contract('TokenBuy', accounts => {
    beforeEach(async () => {
        ovrToken = await OVRToken.new()
        tokenBuy = await TokenBuy.new(ovrToken.address)
        // Add tokens to the tokenBuy contract to distribute them
        const totalSupply = await ovrToken.totalSupply()
        await ovrToken.transfer(tokenBuy.address, totalSupply)
    })
    it('should set the token prices correctly', async () => {
        await tokenBuy.setTokenPrices(priceToSetEth, priceToSetUsd)
        const priceAfterEth = await tokenBuy.tokensPerEth()
        const priceAfterUsd = await tokenBuy.tokensPerUsd()

        assert.equal(priceAfterEth, priceToSetEth, 'The price of ETH must be set correctly')
        assert.equal(priceAfterUsd, priceToSetUsd, 'The price of USD must be set correctly')
    })

    it('should buy tokens properly with ETH', async () => {
        const tokensToBuy = web3.utils.toWei('200') // Must be a string or web3 will bitch about it
        const etherToSend = tokensToBuy / priceToSetEth
        await tokenBuy.setTokenPrices(priceToSetEth, priceToSetUsd)
        await tokenBuy.buyTokensWithEth({
            value: etherToSend, // Must be a string for web3 for precission erros
        })
        const finalBalance = await ovrToken.balanceOf(accounts[0])

        assert.equal(finalBalance, tokensToBuy, 'The final balance must be correct when buying with ETH')
    })

    it('should not allow you to buy OVR tokens when prices are not set', async () => {
        const tokensToBuy = web3.utils.toWei('200') // Must be a string or web3 will bitch about it
        const etherToSend = tokensToBuy / priceToSetEth
        try {
            await tokenBuy.buyTokensWithEth({
                value: etherToSend, // Must be a string for web3 for precission erros
            })
            assert.ok(false, 'The transaction must revert when prices are not set')
        } catch (e) {
            assert.ok(true)
        }
    })

    it('should not allow you to buy OVR tokens when the contract is paused', async () => {
        const tokensToBuy = web3.utils.toWei('200') // Must be a string or web3 will bitch about it
        const etherToSend = tokensToBuy / priceToSetEth
        await tokenBuy.pause()
        try {
            await tokenBuy.buyTokensWithEth({
                value: etherToSend, // Must be a string for web3 for precission erros
            })
            assert.ok(false, 'The transaction must revert when the contract is paused')
        } catch (e) {
            assert.ok(true)
        }
    })
})
