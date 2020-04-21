const assert = require('assert')
const TokenBuy = artifacts.require('TokenBuy')
const OVRToken = artifacts.require('OVRToken')
let tokenBuy = {}
let ovrToken = {}
let transaction = {} // A reusable variable

contract('TokenBuy', () => {
    beforeEach(async () => {
        ovrToken = await OVRToken.new()
        tokenBuy = await TokenBuy.new(ovrToken.address)
    })
    it('should set the token prices correctly', async () => {
        const priceToSetEth = 100
        const priceToSetUsd = 10
        await tokenBuy.setTokenPrices(priceToSetEth, priceToSetUsd)
        const priceAfterEth = await tokenBuy.tokensPerEth()
        const priceAfterUsd = await tokenBuy.tokensPerUsd()

        assert.equal(priceAfterEth, priceToSetEth, 'The price of ETH must be set correctly')
        assert.equal(priceAfterUsd, priceToSetUsd, 'The price of USD must be set correctly')
    })
})

function awaitConfirmation(transaction) {
    let number = 0
    return new Promise((resolve, reject) => {
        transaction.on('confirmation', number => {
            if(number == 1) resolve()
        })
    })
}