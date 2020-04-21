pragma solidity ^0.5.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Ownable {
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner can't be the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


/// The contract to purchase OVR Tokens 
/// Users will send ETH, DAI, USDC or USDT to this contract and receive X tokens in return based on a custom price
/// No need to use oracles, the price will be fixed and there will be a table for:
///  1 ETH -> X tokens
///  1 USD -> X tokens (for those 3 ERC20 tokens since they are stablecoins)
contract TokenBuy is Ownable {
    using SafeMath for uint256;
    address public daiToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // Our deployed token
    address public ovrToken;
    uint256 public tokensPerEth;
    uint256 public tokensPerUsd;

    event TokenPurchase(address from, uint256 ovrPurchased, uint256 coinsPaid, string coinUsed);

    modifier pricesMustBeSet {
        require(tokensPerEth > 0, "The price per ETH must be set");
        require(tokensPerUsd > 0, "The price per ETH must be set");
        _;
    }

    constructor (address _ovrToken) public {
        ovrToken = _ovrToken;
    }

    /// To set the price per token for the given currency used as payment
    function setTokenPrices(uint256 _tokensPerEth, uint256 _tokensPerUsd) public {
        require(_tokensPerEth != 0, "The ETH price can't be zero");
        require(_tokensPerUsd != 0, "The token price can't be zero");
        tokensPerEth = _tokensPerEth;
        tokensPerUsd = _tokensPerUsd;
    }

    /// To buy tokens in ETH the payment will be received in the msg.value
    function buyTokensWithEth() public payable pricesMustBeSet {
        // Check how much value has been sent and send the corresponding value
        uint256 tokensToBuy = msg.value.mul(tokensPerEth);
        IERC20(ovrToken).transfer(msg.sender, tokensToBuy);
        emit TokenPurchase(msg.sender, tokensToBuy, msg.value, 'ETH');
    }

    /// To buy tokens in USDT the user must first approve an exceeding or equal amount of USDT tokens by the price to this contract
    /// The function checks your approval and automatically calculates how many tokens to extract
    /// @param _tokensToBuy is the number of tokens you want to get
    function buyTokensWithUsdt(uint256 _tokensToBuy) public pricesMustBeSet {
        // Check your approval first
        uint256 allowance = IERC20(usdtToken).allowance(msg.sender, address(this));
        uint256 paymentRequiredInUsdt = _tokensToBuy.div(tokensPerUsd);
        require(paymentRequiredInUsdt <= allowance, 'You must approve an equal or exceeing amount of USDT tokens * price to buy those');
        // Transfer the USDT tokens to this contract as the holder
        // Note that this contract is the "approved" person so it should work fine
        IERC20(usdtToken).transferFrom(msg.sender, address(this), paymentRequiredInUsdt);
        emit TokenPurchase(msg.sender, _tokensToBuy, paymentRequiredInUsdt, 'USDT');
    }

    /// To buy tokens in USDC the user must first approve an exceeding or equal amount of USDC tokens by the price to this contract
    /// The function checks your approval and automatically calculates how many tokens to extract
    /// @param _tokensToBuy is the number of tokens you want to get
    function buyTokensWithUsdc(uint256 _tokensToBuy) public pricesMustBeSet {
        // Check your approval first
        uint256 allowance = IERC20(usdcToken).allowance(msg.sender, address(this));
        uint256 paymentRequiredInUsdc = _tokensToBuy.div(tokensPerUsd);
        require(paymentRequiredInUsdc <= allowance, 'You must approve an equal or exceeing amount of USDC tokens * price to buy those');
        // Transfer the USDT tokens to this contract as the holder
        // Note that this contract is the "approved" person so it should work fine
        IERC20(usdcToken).transferFrom(msg.sender, address(this), paymentRequiredInUsdc);
        emit TokenPurchase(msg.sender, _tokensToBuy, paymentRequiredInUsdc, 'USDC');
    }

    /// To buy tokens in DAI the user must first approve an exceeding or equal amount of DAI tokens by the price to this contract
    /// The function checks your approval and automatically calculates how many tokens to extract
    /// @param _tokensToBuy is the number of tokens you want to get
    function buyTokensWithDai(uint256 _tokensToBuy) public pricesMustBeSet {
        // Check your approval first
        uint256 allowance = IERC20(daiToken).allowance(msg.sender, address(this));
        uint256 paymentRequiredInDai = _tokensToBuy.div(tokensPerUsd);
        require(paymentRequiredInDai <= allowance, 'You must approve an equal or exceeing amount of DAI tokens * price to buy those');
        // Transfer the USDT tokens to this contract as the holder
        // Note that this contract is the "approved" person so it should work fine
        IERC20(daiToken).transferFrom(msg.sender, address(this), paymentRequiredInDai);
        emit TokenPurchase(msg.sender, _tokensToBuy, paymentRequiredInDai, 'DAI');
    }

    /// To extract the tokens that may have been sent to this contract by accident
    function extractTokens(address _tokenToExtract, uint256 _amount) public onlyOwner {
        IERC20(_tokenToExtract).transfer(owner, _amount);
    }

    /// To extract the ether stored in this contract
    function extractEth() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    /// Check how much ETH you have to send to receive X amount of tokens
    function calculateHowManyTokensYouCanBuyWithEth(uint256 _tokensToBuy) public view returns(uint256) {
        return _tokensToBuy.div(tokensPerEth);
    }
}