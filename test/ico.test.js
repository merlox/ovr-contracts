const ICO = artifacts.require('ICO')
const OVRToken = artifacts.require('OVRToken')
const OVRLand = artifacts.require('OVRLand')
let ovrToken = {}
let ovrLand = {}
let ico = {}
let accounts = {} // Global accounts
const initialLandCost = String(10e18)

contract.only('ICO', accs => {
	accounts = accs

	beforeEach(async () => {
		ovrToken = await OVRToken.new()
		ovrLand = await OVRLand.new()
		ico = await ICO.new(ovrToken.address, ovrLand.address, initialLandCost)
	})

	it('should set the OVR token, land and initial land bid successfully', async () => {
		ico = await ICO.new(ovrToken.address, ovrLand.address, initialLandCost)
		const token = await ico.ovrToken()
		const land = await ico.ovrLand()
		const initialBid = await ico.initialLandBid()
		expect(token).to.eq(ovrToken.address)
		expect(land).to.eq(ovrLand.address)
		expect(String(initialBid)).to.eq(initialLandCost)
	})

	describe('participateInAuction', async () => {
		it('should create a new auction successfully', async () => {
			await participateInAuction()
		})
		it('should be able to bid for an already started auction')
		it('should not allow you to participate in an ended auction')
		it(
			'should not allow you to participate in an auction with a land outside the current epoch'
		)
		it(
			'should fail to participate in an auction when not given enough token allowance'
		)
		it(
			'should not allow you to participate in an auction when the contract is paused'
		)
		it(
			'should update the auctions[] array successfully after participating in an auction'
		)
	})

	describe('redeemWonLand', async () => {
		it('should be able to redeem a land that you won')
		it("shouldn't allow you to redeem a land that you haven't won")
		it("shouldn't allow you to redeem a land before its auction is finished")
		it(
			'should send you the OVRLand token after redeeming the land successfully'
		)
		it(
			'should set the cashbackAmount correctly after redeeming the land in the lands mapping'
		)
	})

	describe('redeemCashback', async () => {
		it(
			'should allow you to redeem a cashback successfully after winning an auction'
		)
		it(
			"shouldn't allow you to cashback before 30 days after the land auction has been completed"
		)
		it("shouldn't allow you to redeem a casback that's been redeemed already")
		it("shouldn't allow you to redeem a cashback that isn't yours")
		it(
			'should send you the right amount of OVR tokens after redeeming the cashback'
		)
	})

	describe('extractTokens', async () => {
		it('should be able to extract OVR tokens from this contract')
		it(
			"shouldn't allow you to extract tokens if you're not the owner of the contract"
		)
	})

	describe('extractEth', async () => {
		it('should be able to extract ETH from the contract')
		it("shouldn't be able to extract ETH if you're not the contract owner")
	})

	describe('putLandOnSale', async () => {
		it('should be able to sell a land successfully')
		it("shouldn't allow you to sell a land you don't own")
		it("shouldn't allow you to sell a land before its auction is finished")
	})

	describe('buyLand', async () => {
		it('should buy a land successfully')
		it("shouldn't allow you to buy a land not on sale")
		it(
			"shouldn't allow you to buy a land with a snaller allowance than required"
		)
		it("shouldn't allow you to buy a land before ending its auction")
		it('should send the right amount of OVR tokens to the seller')
		it('should send the right OVR land token to the buyer')
	})

	describe('offerToBuyLand', async () => {
		it('should send an offer successfully')
		it("shouldn't send an offer if the land is still in the auction state")
		it("shouldn't send an offer without approving the right token amoun")
		it("shouldn't send an offer with a wrong expiration date")
		it("shouldn't send an offer to a non-existing land")
	})

	describe('respondToBuyOffer', async () => {
		it('should accept a buy offer successfully')
		it('should reject a buy offer successfully')
		it("shouldn't respond to a non-existing offer")
		it("shouldn't respond to an expired offer")
		it("shouldn't respond to an offer with an active auction")
		it(
			"shouldn't allow you to respond to an offer without being the land owner"
		)
	})

	describe('checkMyLandOffer', async () => {
		it('should send you all the land offers for a given id')
	})

	describe('checkWonLands', async () => {
		it("should show you the land that you've won")
	})
})

async function participateInAuction() {
	const landId = String(631272015026578401)
	await ovrToken.approve(ico.address, initialLandCost)
	await ico.participateInAuction(landId)
	const land = await ico.lands(landId)
	expect(land.owner).to.eq(accounts[0])
	expect(String(land.paid)).to.eq(initialLandCost)
	expect(String(land.state)).to.eq('1')
}
