pragma solidity 0.5.0;


contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenBuy is Ownable {
    using SafeMath for uint256;
    address daiToken = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
    address usdcToken = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
    address usdtToken = '0xdac17f958d2ee523a2206206994597c13d831ec7';
    
    address ovrToken;
    uint256 tokenPerEth;
    uint256 tokensPerUsd;

    event TokenPurchase(address from, uint256 ovrPurchased, uint256 coinsPaid, string coinUsed);

    constructor (address _ovrToken) public {
        ovrToken = _ovrToken;
    }

    
    function setTokenPrices(uint256 _tokensPerEth, uint256 _tokensPerUsd) public {
        tokenPerEth = _tokensPerEth;
        tokensPerUsd = _tokensPerUsd;
    }

    
    function buyTokensWithEth() public payable {
        
        uint256 tokensToBuy = msg.value.mul(tokensPerEth);
        IERC20(ovrToken).transfer(msg.sender, tokensToBuy);
        emit TokenPurchase(msg.sender, tokensToBuy, msg.value, 'ETH');
    }

    
    
    
    function buyTokensWithUsdt(uint256 _tokensToBuy) public {
        
        uint256 allowance = IERC20(usdtToken).allowance(msg.sender, address(this));
        uint256 paymentRequiredInUsdt = _tokensToBuy.div(tokensPerUsd);
        require(paymentRequiredInUsdt <= allowance, 'You must approve an equal or exceeing amount of USDT tokens * price to buy those');
        
        
        IERC20(usdtToken).transferFrom(msg.sender, address(this), paymentRequiredInUsdt);
        emit TokenPurchase(msg.sender, _tokensToBuy, paymentRequiredInUsdt, 'USDT');
    }

    
    
    
    function buyTokensWithUsdc(uint256 _tokensToBuy) public {
        
        uint256 allowance = IERC20(usdcToken).allowance(msg.sender, address(this));
        uint256 paymentRequiredInUsdc = _tokensToBuy.div(tokensPerUsd);
        require(paymentRequiredInUsdc <= allowance, 'You must approve an equal or exceeing amount of USDC tokens * price to buy those');
        
        
        IERC20(usdcToken).transferFrom(msg.sender, address(this), paymentRequiredInUsdc);
        emit TokenPurchase(msg.sender, _tokensToBuy, paymentRequiredInUsdc, 'USDC');
    }

    
    
    
    function buyTokensWithDai(uint256 _tokensToBuy) public {
        
        uint256 allowance = IERC20(daiToken).allowance(msg.sender, address(this));
        uint256 paymentRequiredInDai = _tokensToBuy.div(tokensPerUsd);
        require(paymentRequiredInDai <= allowance, 'You must approve an equal or exceeing amount of DAI tokens * price to buy those');
        
        
        IERC20(daiToken).transferFrom(msg.sender, address(this), paymentRequiredInDai);
        emit TokenPurchase(msg.sender, _tokensToBuy, paymentRequiredInDai, 'DAI');
    }

    
    function extractTokens(address _tokenToExtract, uint256 _amount) public onlyOwner {
        IERC20(_tokenToExtract).transfer(owner, _amount);
    }

    
    function extractEth() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    
    function calculateHowManyTokensYouCanBuyWithEth(uint256 _tokensToBuy) public view returns(uint256) {
        return _tokensToBuy.div(tokensPerEth);
    }
}