const BigNumber = require('bignumber.js')
const ICO = artifacts.require('ICO')
const OVRToken = artifacts.require('OVRToken')
const OVRLand = artifacts.require('OVRLand')
let ovrToken = {}
let ovrLand = {}
let ico = {}
let accounts = {} // Global accounts
let initialLandCost
let initialTokens

contract.only('ICO', accs => {
	accounts = accs
	initialLandCost = BigNumber(10e18)
	initialTokens = BigNumber(1000e18) // 1k tokens for each account

	beforeEach(async () => {
		ovrToken = await OVRToken.new()
		ovrLand = await OVRLand.new()
		for (let i = 0; i < 9; i++) {
			await ovrToken.transfer(accounts[i], initialTokens)
		}
		ico = await ICO.new(ovrToken.address, ovrLand.address, initialLandCost)
		await ovrLand.addMinter(ico.address) // Make the ICO contract a ERC721 minter
	})

	it('should set the OVR token, land and initial land bid successfully', async () => {
		ico = await ICO.new(ovrToken.address, ovrLand.address, initialLandCost)
		const token = await ico.ovrToken()
		const land = await ico.ovrLand()
		const initialBid = await ico.initialLandBid()
		expect(token).to.eq(ovrToken.address)
		expect(land).to.eq(ovrLand.address)
		expect(BigNumber(initialBid)).to.deep.equal(BigNumber(initialLandCost))
	})

	describe('participateInAuction', async () => {
		it('should create a new auction successfully', async () => {
			await participateInAuction(accounts[0], initialLandCost)
		})
		it('should be able to bid for an already started auction', async () => {
			await participateInAuction(accounts[0], initialLandCost)
			await participateInAuction(accounts[1], BigNumber(initialLandCost * 2))
		})
		it('should not allow you to participate in an ended auction', async () => {
			await participateInAuction(accounts[0], initialLandCost)
			await advanceTimeAndBlock(25 * 60 * 60) // 25 hours
			try {
				await participateInAuction(accounts[1], BigNumber(initialLandCost * 2))
				expect.fail('The contract should throw when bidding ended auctions')
			} catch (e) {
				if (
					e.message == 'The contract should throw when bidding ended auctions'
				) {
					expect.fail('The contract should throw when bidding ended auctions')
				}
				expect(e.reason).to.eq('This land auction has ended')
			}
		})
		it('should not allow you to participate in an auction with a land outside the current epoch', async () => {
			try {
				await participateInAuction(
					accounts[0],
					initialLandCost,
					'631272015026578499'
				)
				expect.fail('The contract should throw when bidding outside the epoch')
			} catch (e) {
				if (
					e.message ==
					'The contract should throw when bidding outside the epoch'
				) {
					expect.fail(
						'The contract should throw when bidding outside the epoch'
					)
				}
				expect(e.reason).to.eq("This land isn't available at the current epoch")
			}
		})
		it('should fail to participate in an auction when not given enough token allowance', async () => {
			try {
				await participateInAuction(accounts[0], BigNumber(1e18))
				expect.fail('The contract should throw when not given enough allowance')
			} catch (e) {
				if (
					e.message ==
					'The contract should throw when not given enough allowance'
				) {
					expect.fail(
						'The contract should throw when not given enough allowance'
					)
				}
				expect(e.reason).to.eq(
					'Your allowance must equal or exceed the cost of participating in this auction'
				)
			}
		})
		it('should not allow you to participate in an auction when the contract is paused', async () => {
			await ico.pause()
			try {
				await participateInAuction(accounts[0], initialLandCost)
				expect.fail('The contract should throw when the auction is paused')
			} catch (e) {
				if (
					e.message == 'The contract should throw when the auction is paused'
				) {
					expect.fail('The contract should throw when the auction is paused')
				}
				expect(e.reason).to.eq('Pausable: paused')
			}
		})
		it('should update the activeLands array successfully after participating in an auction', async () => {
			await participateInAuction(accounts[0], initialLandCost)
			const activeLands = await ico.getActiveLands()
			expect(activeLands.length).to.eq(1)
		})
	})

	describe('redeemWonLand', async () => {
		it('should be able to redeem a land that you won', async () => {
			const landId = String(631272015026578401)
			await participateInAuction(accounts[0], initialLandCost, landId)
			await advanceTimeAndBlock(25 * 60 * 60) // 25 hours
			await ico.redeemWonLand(landId)
		})
		it("shouldn't allow you to redeem a land that you haven't won", async () => {
			const landId = String(631272015026578401)
			const landId2 = String(631244444444444444)
			await participateInAuction(accounts[0], initialLandCost, landId)
			await advanceTimeAndBlock(25 * 60 * 60) // 25 hours

			try {
				await ico.redeemWonLand(landId2)
				expect.fail(
					'The contract should throw when trying to redeem an external land'
				)
			} catch (e) {
				if (
					e.message ==
					'The contract should throw when trying to redeem an external land'
				) {
					expect.fail(
						'The contract should throw when trying to redeem an external land'
					)
				}
				expect(e.reason).to.eq('You must be the land winner to redeem it')
			}
		})
		it("shouldn't allow you to redeem a land before its auction is finished", async () => {
			const landId = String(631272015026578401)
			await participateInAuction(accounts[0], initialLandCost)

			try {
				await ico.redeemWonLand(landId)
				expect.fail(
					'The contract should throw when trying to redeem a land still in auction'
				)
			} catch (e) {
				if (
					e.message ==
					'The contract should throw when trying to redeem a land still in auction'
				) {
					expect.fail(
						'The contract should throw when trying to redeem a land still in auction'
					)
				}
				expect(e.reason).to.eq(
					"You can't redeem this land until its auction is finished"
				)
			}
		})
		it('should send you the OVRLand token after redeeming the land successfully', async () => {
			const landId = String(631272015026578401)
			await participateInAuction(accounts[0], initialLandCost, landId)
			await advanceTimeAndBlock(25 * 60 * 60) // 25 hours
			await ico.redeemWonLand(landId)
			const owner = await ovrLand.ownerOf(landId)
			expect(owner).to.eq(accounts[0])
		})
		it('should set the cashbackAmount correctly after redeeming the land in the lands mapping', async () => {
			const landId = String(631272015026578401)
			await participateInAuction(accounts[0], initialLandCost, landId)
			await advanceTimeAndBlock(25 * 60 * 60) // 25 hours
			await ico.redeemWonLand(landId)
			const land = await ico.lands(landId)
			const cashback = BigNumber(land.paid * 0.95).toFixed()
			expect(BigNumber(land.cashbackAmount).toFixed()).to.eq(cashback)
		})
	})

	describe('redeemCashback', async () => {
		it('should allow you to redeem a cashback successfully after winning an auction', async () => {
			const tokensBefore = await ovrToken.balanceOf(accounts[0])
			const landId = String(631272015026578401)
			await participateInAuction(accounts[0], initialLandCost, landId)
			await advanceTimeAndBlock(25 * 60 * 60) // 25 hours
			await ico.redeemWonLand(landId)
			await advanceTimeAndBlock(30 * 24 * 60 * 60) // 30 days
			await ico.redeemCashback(landId)
			const tokensAfter = await ovrToken.balanceOf(accounts[0])
			// Considering the 95% initial month cashback
			const before = BigNumber(tokensBefore - initialLandCost * 0.05).toFixed()

			expect(before).to.eq(BigNumber(tokensAfter).toFixed())
		})
		it("shouldn't allow you to cashback before 30 days after the land auction has been completed", async () => {
			const landId = String(631272015026578401)
			await participateInAuction(accounts[0], initialLandCost, landId)
			await advanceTimeAndBlock(25 * 60 * 60) // 25 hours
			await ico.redeemWonLand(landId)

			try {
				await ico.redeemCashback(landId)
				expect.fail(
					'The contract should throw when trying to redeem a cashback before 30 days'
				)
			} catch (e) {
				if (
					e.message ==
					'The contract should throw when trying to redeem a cashback before 30 days'
				) {
					expect.fail(
						'The contract should throw when trying to redeem a cashback before 30 days'
					)
				}
				expect(e.reason).to.eq("You can't redeem a cashback before 30 days")
			}
		})
		it("shouldn't redeem a cashback that hasn't been land redeemed yet", async () => {
			const landId = String(631272015026578401)
			await participateInAuction(accounts[0], initialLandCost, landId)
			await advanceTimeAndBlock(25 * 60 * 60) // 25 hours
			await advanceTimeAndBlock(30 * 24 * 60 * 60) // 30 days

			try {
				await ico.redeemCashback(landId)
				expect.fail(
					'The contract should throw when trying to redeem a cashback before the land has been redeemed'
				)
			} catch (e) {
				if (
					e.message ==
					'The contract should throw when trying to redeem a cashback before the land has been redeemed'
				) {
					expect.fail(
						'The contract should throw when trying to redeem a cashback before the land has been redeemed'
					)
				}
				expect(e.reason).to.eq(
					'The land must be redeemed before getting its cashback'
				)
			}
		})
		it("shouldn't redeem a cashback that's been redeemed already", async () => {
			const landId = String(631272015026578401)
			await participateInAuction(accounts[0], initialLandCost, landId)
			await advanceTimeAndBlock(25 * 60 * 60) // 25 hours
			await ico.redeemWonLand(landId)
			await advanceTimeAndBlock(30 * 24 * 60 * 60) // 30 days
			await ico.redeemCashback(landId)

			try {
				await ico.redeemCashback(landId)
				expect.fail(
					'The contract should throw when trying to redeem a cashback that has been redeemed already'
				)
			} catch (e) {
				if (
					e.message ==
					'The contract should throw when trying to redeem a cashback that has been redeemed already'
				) {
					expect.fail(
						'The contract should throw when trying to redeem a cashback that has been redeemed already'
					)
				}
				expect(e.reason).to.eq(
					'The cashback has already been redeemed for this land'
				)
			}
		})
		it("shouldn't allow you to redeem a cashback that isn't yours", async () => {
			const landId = String(631272015026578401)
			await participateInAuction(accounts[0], initialLandCost, landId)
			await advanceTimeAndBlock(25 * 60 * 60) // 25 hours
			await ico.redeemWonLand(landId)
			await advanceTimeAndBlock(30 * 24 * 60 * 60) // 30 days

			try {
				await ico.redeemCashback(landId, {
					from: accounts[1],
				})
				expect.fail(
					"The contract should throw when trying to redeem a cashback that isn't yours"
				)
			} catch (e) {
				if (
					e.message ==
					"The contract should throw when trying to redeem a cashback that isn't yours"
				) {
					expect.fail(
						"The contract should throw when trying to redeem a cashback that isn't yours"
					)
				}
				expect(e.reason).to.eq(
					'You must be the land owner to redeem its cashback'
				)
			}
		})
	})

	describe('extractTokens', async () => {
		it('should be able to extract OVR tokens from this contract', async () => {
			// The contract earns money when a land is sold
			const initialBalanceOwner = ovrToken.balanceOf(accounts[0])
			const landId = String(631272015026578401)
			await participateInAuction(accounts[1], initialLandCost, landId)
			await advanceTimeAndBlock(25 * 60 * 60) // 25 hours
			await ico.redeemWonLand(landId, {
				from: accounts[1],
			})

			await ico.extractTokens(ovrToken.address, initialLandCost)
			const finalBalanceOwner = ovrToken.balanceOf(accounts[0])

			expect(BigNumber(initialBalanceOwner + initialLandCost).toFixed()).to.eq(
				BigNumber(finalBalanceOwner).toFixed()
			)
		})
		it("shouldn't allow you to extract tokens if you're not the owner of the contract", async () => {
			const landId = String(631272015026578401)
			await participateInAuction(accounts[1], initialLandCost, landId)
			await advanceTimeAndBlock(25 * 60 * 60) // 25 hours
			await ico.redeemWonLand(landId, {
				from: accounts[1],
			})

			try {
				await ico.extractTokens(ovrToken.address, initialLandCost, {
					from: accounts[1],
				})
				expect.fail("You aren't allowed to extract tokens from the contract")
			} catch (e) {
				if (
					e.message == "You aren't allowed to extract tokens from the contract"
				) {
					expect.fail("You aren't allowed to extract tokens from the contract")
				}
				expect(e.reason).to.eq('Ownable: caller is not the owner')
			}
		})
	})

	describe('putLandOnSale', async () => {
		it('should be able to put a land on sale successfully', async () => {
			const landId = String(631272015026578401)
			await winLandAuction(accounts[0])
			await ovrLand.approve(ico.address, landId)
			await ico.putLandOnSale(landId, initialLandCost, true)

			// Check its on sale
			const landsOnSale = await ico.getLandsOnSaleOrSold()
			const land = await ico.lands(landId)
			expect(landsOnSale.length).to.eq(1)
			expect(BigNumber(landsOnSale[0]).toFixed()).to.eq(landId)
			expect(land.onSale).to.eq(true)
			expect(BigNumber(land.sellPrice).toFixed()).to.eq(
				BigNumber(initialLandCost).toFixed()
			)
		})
		it('should be able to remove a land from the market successfully', async () => {
			const landId = String(631272015026578401)
			await winLandAuction(accounts[0])
			await ovrLand.approve(ico.address, landId)
			await ico.putLandOnSale(landId, initialLandCost, true)

			// Check its on sale
			let landsOnSale = await ico.getLandsOnSaleOrSold()
			let land = await ico.lands(landId)
			expect(landsOnSale.length).to.eq(1)
			expect(BigNumber(landsOnSale[0]).toFixed()).to.eq(landId)
			expect(land.onSale).to.eq(true)
			expect(BigNumber(land.sellPrice).toFixed()).to.eq(
				BigNumber(initialLandCost).toFixed()
			)

			await ico.putLandOnSale(landId, initialLandCost, false)
			landsOnSale = await ico.getLandsOnSaleOrSold()
			land = await ico.lands(landId)
			expect(landsOnSale.length).to.eq(2)
			expect(land.onSale).to.eq(false)
		})
		it("shouldn't allow you to put a land on sale without approving the ERC721 token first", async () => {
			const landId = String(631272015026578401)
			await winLandAuction(accounts[0])
			try {
				await ico.putLandOnSale(landId, initialLandCost, true)
				expect.fail('You must approve the ERC721 land token first')
			} catch (e) {
				if (e.message == 'You must approve the ERC721 land token first') {
					expect.fail('You must approve the ERC721 land token first')
				}
				expect(e.reason).to.eq(
					'You must approve this contract to manage your ERC721 token'
				)
			}
		})
		it("shouldn't allow you to sell a land you don't own", async () => {
			const landId = String(631272015026578401)
			await winLandAuction(accounts[0])
			try {
				await ico.putLandOnSale(landId, initialLandCost, true, {
					from: accounts[1],
				})
				expect.fail('You can only sell your own land')
			} catch (e) {
				if (e.message == 'You can only sell your own land') {
					expect.fail('You can only sell your own land')
				}
				expect(e.reason).to.eq('You must be the land owner to put it on sale')
			}
		})
		it("shouldn't allow you to sell a land before its auction is finished", async () => {
			const landId = String(631272015026578401)
			await participateInAuction(accounts[0], initialLandCost, landId)
			// The auction is still not done so he shouldn't be able to put it on sale
			try {
				await ico.putLandOnSale(landId, initialLandCost, true)
				expect.fail("You can't sell a land before the auction is finished")
			} catch (e) {
				if (
					e.message == "You can't sell a land before the auction is finished"
				) {
					expect.fail("You can't sell a land before the auction is finished")
				}
				expect(e.reason).to.eq(
					'The land auction must have been completed to put it on sale'
				)
			}
		})
	})

	describe('buyLand', async () => {
		it('should buy a land successfully', async () => {
			const landId = String(631272015026578401)
			await winLandAuction(accounts[0])
			await ovrLand.approve(ico.address, landId)
			await ico.putLandOnSale(landId, initialLandCost, true)

			await ovrToken.approve(ico.address, initialLandCost, {
				from: accounts[1],
			})
			await ico.buyLand(landId, { from: accounts[1] })
		})
		it('should send the right amount of OVR tokens to the seller', async () => {
			const landId = String(631272015026578401)
			await winLandAuction(accounts[0])
			const initialTokenBalance = await ovrToken.balanceOf(accounts[0])
			await ovrLand.approve(ico.address, landId)
			await ico.putLandOnSale(landId, initialLandCost, true)

			await ovrToken.approve(ico.address, initialLandCost, {
				from: accounts[1],
			})
			await ico.buyLand(landId, { from: accounts[1] })

			const finalTokenBalance = await ovrToken.balanceOf(accounts[0])
			const initial = BigNumber(initialTokenBalance).plus(
				BigNumber(initialLandCost)
			)
			expect(initial.toFixed()).to.eq(BigNumber(finalTokenBalance).toFixed())
		})
		it('should send the right OVR ERC721 land token to the buyer', async () => {
			const landId = String(631272015026578401)
			await winLandAuction(accounts[0])
			await ovrLand.approve(ico.address, landId)
			await ico.putLandOnSale(landId, initialLandCost, true)

			await ovrToken.approve(ico.address, initialLandCost, {
				from: accounts[1],
			})
			await ico.buyLand(landId, { from: accounts[1] })
			const landOwner = await ovrLand.ownerOf(landId)

			expect(landOwner).to.eq(accounts[1])
		})
		it("shouldn't allow you to buy a land not on sale", async () => {
			const landId = String(631272015026578401)
			await winLandAuction(accounts[0])
			await ovrToken.approve(ico.address, initialLandCost)
			try {
				await ico.buyLand(landId)
				expect.fail('The land is not on sale it should throw')
			} catch (e) {
				if (e.message == 'The land is not on sale it should throw') {
					expect.fail('The land is not on sale it should throw')
				}
				expect(e.reason).to.eq('The land must be on sale to buy it')
			}
		})
		it("shouldn't allow you to buy a land with a smaller allowance than required", async () => {
			const landId = String(631272015026578401)
			await winLandAuction(accounts[0])
			await ovrLand.approve(ico.address, landId)
			await ico.putLandOnSale(landId, initialLandCost, true)
			await ovrToken.approve(
				ico.address,
				BigNumber(initialLandCost / 2).toFixed(),
				{ from: accounts[1] }
			)
			try {
				await ico.buyLand(landId, { from: accounts[1] })
				expect.fail('The allowance is not enough it should fail')
			} catch (e) {
				if (e.message == 'The allowance is not enough it should fail') {
					expect.fail('The allowance is not enough it should fail')
				}
				expect(e.reason).to.eq(
					'You must approve the right amount of OVR tokens to buy this land'
				)
			}
		})
	})

	describe.only('offerToBuyLand', async () => {
		it('should send an offer successfully', async () => {
			const landId = String(631272015026578401)
			const expiration = Date.now() + 10000000
			await winLandAuction(accounts[0], landId)
			await ico.offerToBuyLand(landId, initialLandCost, expiration, {
				from: accounts[1],
			})
		})
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

async function participateInAuction(sender, approvalAmount, _landId) {
	const landId = _landId ? _landId : String(631272015026578401)

	await ovrToken.approve(ico.address, approvalAmount, {
		from: sender,
	})
	await ico.participateInAuction(landId, {
		from: sender,
	})
	const land = await ico.lands(landId)
	expect(land.owner).to.eq(sender)
	expect(BigNumber(land.paid).toFixed()).to.eql(
		BigNumber(approvalAmount).toFixed()
	)
	expect(String(land.state)).to.eq('1')
}

async function winLandAuction(sender, _landId) {
	const landId = _landId ? _landId : String(631272015026578401)
	await participateInAuction(sender, initialLandCost, landId)
	await advanceTimeAndBlock(25 * 60 * 60) // 25 hours
	await ico.redeemWonLand(landId, {
		from: sender,
	})
}

const advanceTimeAndBlock = async time => {
	await advanceTime(time)
	await advanceBlock()

	return Promise.resolve(web3.eth.getBlock('latest'))
}

const advanceTime = time => {
	return new Promise((resolve, reject) => {
		web3.currentProvider.send(
			{
				jsonrpc: '2.0',
				method: 'evm_increaseTime',
				params: [time],
				id: new Date().getTime(),
			},
			(err, result) => {
				if (err) {
					return reject(err)
				}
				return resolve(result)
			}
		)
	})
}

const advanceBlock = () => {
	return new Promise((resolve, reject) => {
		web3.currentProvider.send(
			{
				jsonrpc: '2.0',
				method: 'evm_mine',
				id: new Date().getTime(),
			},
			(err, result) => {
				if (err) {
					return reject(err)
				}
				const newBlockHash = web3.eth.getBlock('latest').hash

				return resolve(newBlockHash)
			}
		)
	})
}
