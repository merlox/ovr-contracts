const assert = require('assert')
const ICO = artifacts.require('ICO')
const OVRToken = artifacts.require('OVRToken')
const OVRLand = artifacts.require('OVRLand')
let ovrToken = {}
let ovrLand = {}
let ico = {}
let accounts = {} // Global accounts
const priceToSetEth = 100
const priceToSetUsd = 10

contract('ICO', accs => {
    accounts = accs

    beforeEach(async () => {
        ovrToken = await OVRToken.new()
        ovrLand = await OVRLand.new()
        ico = await ICO.new(ovrToken.address, ovrLand.address, 10e18)
    })

    it('should set the OVR token, land and initial land bid successfully', async () => {
        ico = await ICO.new(ovrToken.address, ovrLand.address, 10e18)
        console.log('expect', expect)
    })
})