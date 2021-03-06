pragma solidity ^0.5.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/lifecycle/Pausable.sol';
import './usingProvable.sol';

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
contract TokenBuy is Ownable, Pausable, usingProvable {
    using SafeMath for uint256;
    address public daiToken;
    address public usdcToken;
    address public usdtToken;
    // Our deployed token
    address public ovrToken;
    // You get X tokens for 1 USD where X is this variable
    uint256 public tokensPerUsd = 10; // 1 usd is 10 tokens
    uint256 public ethPrice = 240; // Temporary initial price until it gets updated by the oracle


    mapping(bytes32=>bool) validIds;

    event TokenPurchase(address from, uint256 ovrPurchased, uint256 coinsPaid, string coinUsed);
    event PriceUpdated(uint256 date, uint256 price);

    modifier pricesMustBeSet {
        require(tokensPerUsd > 0, "The price per ETH must be set");
        _;
    }

    /// These are the official addresses
    /// daiToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    /// usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    /// usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    constructor (address _ovrToken, address _daiToken, address _usdcToken, address _usdtToken) public payable {
        require(_ovrToken != address(0), "The OVR token address can't be empty");
        require(_daiToken != address(0), "The DAI token address can't be empty");
        require(_usdcToken != address(0), "The USDC token address can't be empty");
        require(_usdtToken != address(0), "The USDT token address can't be empty");
        daiToken = _daiToken;
        usdcToken = _usdcToken;
        usdtToken = _usdtToken;
        ovrToken = _ovrToken;

        updatePrice();
    }

    function updatePrice() public payable {
        bytes32 queryId = provable_query(0, "URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price", 500000);
        validIds[queryId] = true;
    }

    /// Oraclize callback
    function __callback(bytes32 myid, string memory result) public {
        if (!validIds[myid]) revert();
        if (msg.sender != provable_cbAddress()) revert();
        ethPrice = safeParseInt(result);
        emit PriceUpdated(now, ethPrice);

        // Call it every day
        bytes32 queryId = provable_query(86400, "URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price", 500000);
        validIds[queryId] = true;
    }

    /// To buy tokens in ETH the payment will be received in the msg.value
    function buyTokensWithEth(uint256 _tokenstoBuy) public payable pricesMustBeSet whenNotPaused {
        require(msg.value > 0, "You must send a value to buy tokens with ETH");
        // Check how much value has been sent and send the corresponding value
        uint256 calculatedTokensToBuy = msg.value.mul(ethPrice).mul(tokensPerUsd);
        require(calculatedTokensToBuy >= _tokenstoBuy, 'You must send more or equal the value of tokens to buy');
        IERC20(ovrToken).transfer(msg.sender, _tokenstoBuy);
        emit TokenPurchase(msg.sender, _tokenstoBuy, msg.value, 'ETH');
    }

    /// To buy tokens in USDT the user must first approve an exceeding or equal amount of USDT tokens by the price to this contract
    /// The function checks your approval and automatically calculates how many tokens to extract
    /// @param _tokensToBuy is the number of tokens you want to get WITH the 18 decimals
    function buyTokensWithUsdt(uint256 _tokensToBuy) public pricesMustBeSet whenNotPaused {
        // Check your approval first
        uint256 allowance = IERC20(usdtToken).allowance(msg.sender, address(this));
        uint256 paymentRequiredInUsdt = _tokensToBuy.div(tokensPerUsd);
        require(paymentRequiredInUsdt <= allowance, 'You must approve an equal or exceeding amount of USDT tokens / 10 to buy those');
        // Transfer the USDT tokens to this contract as the holder
        // Note that this contract is the "approved" person so it should work fine
        IERC20(usdtToken).transferFrom(msg.sender, address(this), paymentRequiredInUsdt);
        IERC20(ovrToken).transfer(msg.sender, _tokensToBuy);
        emit TokenPurchase(msg.sender, _tokensToBuy, paymentRequiredInUsdt, 'USDT');
    }

    /// To buy tokens in USDC the user must first approve an exceeding or equal amount of USDC tokens by the price to this contract
    /// The function checks your approval and automatically calculates how many tokens to extract
    /// @param _tokensToBuy is the number of tokens you want to get WITH the 18 decimals
    function buyTokensWithUsdc(uint256 _tokensToBuy) public pricesMustBeSet whenNotPaused {
        // Check your approval first
        uint256 allowance = IERC20(usdcToken).allowance(msg.sender, address(this));
        uint256 paymentRequiredInUsdc = _tokensToBuy.div(tokensPerUsd);
        require(paymentRequiredInUsdc <= allowance, 'You must approve an equal or exceeding amount of USDC tokens / 10 to buy those');
        // Transfer the USDT tokens to this contract as the holder
        // Note that this contract is the "approved" person so it should work fine
        IERC20(usdcToken).transferFrom(msg.sender, address(this), paymentRequiredInUsdc);
        IERC20(ovrToken).transfer(msg.sender, _tokensToBuy);
        emit TokenPurchase(msg.sender, _tokensToBuy, paymentRequiredInUsdc, 'USDC');
    }

    /// To buy tokens in DAI the user must first approve an exceeding or equal amount of DAI tokens by the price to this contract
    /// The function checks your approval and automatically calculates how many tokens to extract
    /// @param _tokensToBuy is the number of tokens you want to get WITH the 18 decimals
    function buyTokensWithDai(uint256 _tokensToBuy) public pricesMustBeSet whenNotPaused {
        // Check your approval first
        uint256 allowance = IERC20(daiToken).allowance(msg.sender, address(this));
        uint256 paymentRequiredInDai = _tokensToBuy.div(tokensPerUsd);
        require(paymentRequiredInDai <= allowance, 'You must approve an equal or exceeding amount of DAI tokens / 10 to buy those');
        // Transfer the USDT tokens to this contract as the holder
        // Note that this contract is the "approved" person so it should work fine
        IERC20(daiToken).transferFrom(msg.sender, address(this), paymentRequiredInDai);
        IERC20(ovrToken).transfer(msg.sender, _tokensToBuy);
        emit TokenPurchase(msg.sender, _tokensToBuy, paymentRequiredInDai, 'DAI');
    }

    /// To extract the tokens that may have been sent to this contract by accident
    function extractTokens(address _tokenToExtract, uint256 _amount) public onlyOwner whenNotPaused {
        IERC20(_tokenToExtract).transfer(owner, _amount);
    }

    /// To extract the ether stored in this contract
    function extractEth() public onlyOwner whenNotPaused {
        owner.transfer(address(this).balance);
    }

    /// Transfer tokens to those that buy with credit card
    function sendTokensCreditCard(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        IERC20(ovrToken).transfer(_to, _amount);
    }
}