pragma solidity ^0.5.0;

/// The contract to purchase OVR Tokens 
/// Users will send ETH, DAI, USDC or USDT to this contract and receive X tokens in return based on a custom price
/// No need to use oracles, the price will be fixed and there will be a table for:
///  1 ETH -> X tokens
///  1 USD -> X tokens (for those 3 ERC20 tokens since they are stablecoins)
contract TokenBuy {

}