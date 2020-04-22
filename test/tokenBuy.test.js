const assert = require('assert')
const TokenBuy = artifacts.require('TokenBuy')
const OVRToken = artifacts.require('OVRToken')
const ERC20 = artifacts.require('ERC20')
let tokenBuy = {}
let ovrToken = {}
let usdcToken = {}
let usdtToken = {}
let daiToken = {}
let accounts = {} // Global accounts
const priceToSetEth = 100
const priceToSetUsd = 10


contract('TokenBuy', accs => {
    accounts = accs
    
    beforeEach(async () => {
        ovrToken = await OVRToken.new()
        usdcToken = await ERC20.new()
        usdtToken = await ERC20.new()
        daiToken = await ERC20.new()
        tokenBuy = await TokenBuy.new(ovrToken.address, daiToken.address, usdcToken.address, usdtToken.address)
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

    it('should buy tokens properly with USDC', async () => {
        const tokensToBuy = web3.utils.toWei(new web3.utils.BN(10)) // Must be a string or BN
        const finalBalance = await buyTokens('usdc', tokensToBuy)
        assert.ok(finalBalance.eq(tokensToBuy), 'The final balance must be correct when buying with USDC')
    })

    it('should buy tokens properly with DAI', async () => {
        const tokensToBuy = web3.utils.toWei(new web3.utils.BN(10)) // Must be a string or BN
        const finalBalance = await buyTokens('dai', tokensToBuy)
        assert.ok(finalBalance.eq(tokensToBuy), 'The final balance must be correct when buying with DAI')
    })

    it('should buy tokens properly with USDT', async () => {
        const tokensToBuy = web3.utils.toWei(new web3.utils.BN(10)) // Must be a string or BN
        const finalBalance = await buyTokens('usdt', tokensToBuy)
        assert.ok(finalBalance.eq(tokensToBuy), 'The final balance must be correct when buying with USDT')
    })

    it('should extract DAI tokens successfully', async () => {
        const initialDaiBalance = await daiToken.balanceOf(accounts[0])
        const tokensToBuy = web3.utils.toWei(new web3.utils.BN(10)) // Must be a string or BN
        const price = tokensToBuy.div(new web3.utils.BN(priceToSetUsd))
        const finalBalance = await buyTokens('dai', tokensToBuy)
        const secondDaiBalance = await daiToken.balanceOf(accounts[0])
        assert.ok(finalBalance.eq(tokensToBuy), 'The final balance must be correct when buying with DAI')
        assert.ok(initialDaiBalance.sub(price).eq(secondDaiBalance), 'The balance of DAI must be reduced')

        // Then extract them
        await tokenBuy.extractTokens(daiToken.address, price)
        const finalTokenBalance = await daiToken.balanceOf(accounts[0])
        assert.ok(initialDaiBalance.eq(finalTokenBalance), 'You must have your extracted DAI tokens')
    })

    it('should extract USDT tokens successfully', async () => {
        const initialUsdtBalance = await usdtToken.balanceOf(accounts[0])
        const tokensToBuy = web3.utils.toWei(new web3.utils.BN(10)) // Must be a string or BN
        const price = tokensToBuy.div(new web3.utils.BN(priceToSetUsd))
        const finalBalance = await buyTokens('usdt', tokensToBuy)
        const secondUsdtBalance = await usdtToken.balanceOf(accounts[0])
        assert.ok(finalBalance.eq(tokensToBuy), 'The final balance must be correct when buying with USDT')
        assert.ok(initialUsdtBalance.sub(price).eq(secondUsdtBalance), 'The balance of USDT must be reduced')

        // Then extract them
        await tokenBuy.extractTokens(usdtToken.address, price)
        const finalTokenBalance = await usdtToken.balanceOf(accounts[0])
        assert.ok(initialUsdtBalance.eq(finalTokenBalance), 'You must have your extracted USDT tokens')
    })

    it('should extract USDC tokens successfully', async () => {
        const initialUsdcBalance = await usdcToken.balanceOf(accounts[0])
        const tokensToBuy = web3.utils.toWei(new web3.utils.BN(10)) // Must be a string or BN
        const price = tokensToBuy.div(new web3.utils.BN(priceToSetUsd))
        const finalBalance = await buyTokens('usdc', tokensToBuy)
        const secondUsdcBalance = await usdcToken.balanceOf(accounts[0])
        assert.ok(finalBalance.eq(tokensToBuy), 'The final balance must be correct when buying with USDC')
        assert.ok(initialUsdcBalance.sub(price).eq(secondUsdcBalance), 'The balance of USDC must be reduced')

        // Then extract them
        await tokenBuy.extractTokens(usdcToken.address, price)
        const finalTokenBalance = await usdcToken.balanceOf(accounts[0])
        assert.ok(initialUsdcBalance.eq(finalTokenBalance), 'You must have your extracted USDC tokens')
    })

    it('should extract the ETH stored in the contract successfully', async () => {
        const initialEthBalance = await web3.eth.getBalance(accounts[0])
        const tokensToBuy = web3.utils.toWei('200') // Must be a string or web3 will bitch about it
        const etherToSend = tokensToBuy / priceToSetEth
        await tokenBuy.setTokenPrices(priceToSetEth, priceToSetUsd)
        await tokenBuy.buyTokensWithEth({
            value: etherToSend, // Must be a string for web3 for precission erros
        })
        const finalBalance = await ovrToken.balanceOf(accounts[0])
        assert.equal(finalBalance, tokensToBuy, 'The final balance must be correct when buying with ETH')
        const midEthBalance = await web3.eth.getBalance(accounts[0])
        assert.ok(initialEthBalance > midEthBalance, 'The mid balance should be lower in ETH')
        // Then extract them
        await tokenBuy.extractEth()
        const finalEthBalance = await web3.eth.getBalance(accounts[0])
        assert.ok(finalEthBalance > midEthBalance, 'You must have extracted ETH coins')
    })
})


async function buyTokens(tokenType, tokensToBuy) {
    const price = tokensToBuy.div(new web3.utils.BN(priceToSetUsd))
    await tokenBuy.setTokenPrices(priceToSetEth, priceToSetUsd)
    // First approve the exact amount of tokens
    switch (tokenType) {
        case 'dai':
            await daiToken.approve(tokenBuy.address, price)
            await tokenBuy.buyTokensWithDai(tokensToBuy)
            break
        case 'usdt':
            await usdtToken.approve(tokenBuy.address, price)
            await tokenBuy.buyTokensWithUsdt(tokensToBuy)
            break
        case 'usdc':
            await usdcToken.approve(tokenBuy.address, price)
            await tokenBuy.buyTokensWithUsdc(tokensToBuy)
            break
    }
    const finalBalance = await ovrToken.balanceOf(accounts[0])
    return finalBalance 
}