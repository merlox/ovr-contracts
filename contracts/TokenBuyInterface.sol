pragma solidity ^0.5.0;

contract TokenBuyInterface {
    function setTokenPrices(uint256 _tokensPerEth, uint256 _tokensPerUsd) public;
    function buyTokensWithEth() public payable;
    function buyTokensWithUsdt(uint256 _tokensToBuy) public;
    function buyTokensWithUsdc(uint256 _tokensToBuy) public;
    function buyTokensWithDai(uint256 _tokensToBuy) public;
    function extractTokens(address _tokenToExtract, uint256 _amount) public;
    function extractEth() public;
    function sendTokensCreditCard(address _to, uint256 _amount) public;
    function calculateHowManyTokensYouCanBuyWithEth(uint256 _tokensToBuy) public view returns(uint256);
    function ovrToken() public returns(address);
    function tokensPerEth() public returns(uint256);
    function tokensPerUsd() public returns(uint256);
    function daiToken() public returns(address);
    function usdtToken() public returns(address);
    function usdcToken() public returns(address);
}