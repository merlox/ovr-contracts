pragma solidity ^0.5.0;


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

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

contract Pausable is Context, PauserRole {
    
    event Paused(address account);

    
    event Unpaused(address account);

    bool private _paused;

    
    constructor () internal {
        _paused = false;
    }

    
    function paused() public view returns (bool) {
        return _paused;
    }

    
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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

contract TokenBuy is Ownable, Pausable {
    using SafeMath for uint256;
    address public daiToken;
    address public usdcToken;
    address public usdtToken;
    
    address public ovrToken;
    
    uint256 public tokensPerEth;
    
    uint256 public tokensPerUsd;

    event TokenPurchase(address from, uint256 ovrPurchased, uint256 coinsPaid, string coinUsed);

    modifier pricesMustBeSet {
        require(tokensPerEth > 0, "The price per ETH must be set");
        require(tokensPerUsd > 0, "The price per ETH must be set");
        _;
    }

    
    
    
    
    constructor (address _ovrToken, address _daiToken, address _usdcToken, address _usdtToken) public {
        require(_ovrToken != address(0), "The OVR token address can't be empty");
        require(_daiToken != address(0), "The DAI token address can't be empty");
        require(_usdcToken != address(0), "The USDC token address can't be empty");
        require(_usdtToken != address(0), "The USDT token address can't be empty");
        daiToken = _daiToken;
        usdcToken = _usdcToken;
        usdtToken = _usdtToken;
        ovrToken = _ovrToken;
    }

    
    function setTokenPrices(uint256 _tokensPerEth, uint256 _tokensPerUsd) public whenNotPaused {
        require(_tokensPerEth != 0, "The ETH price can't be zero");
        require(_tokensPerUsd != 0, "The token price can't be zero");
        tokensPerEth = _tokensPerEth;
        tokensPerUsd = _tokensPerUsd;
    }

    
    function buyTokensWithEth() public payable pricesMustBeSet whenNotPaused {
        require(msg.value > 0, "You must send a value to buy tokens with ETH");
        
        uint256 tokensToBuy = msg.value.mul(tokensPerEth);
        IERC20(ovrToken).transfer(msg.sender, tokensToBuy);
        emit TokenPurchase(msg.sender, tokensToBuy, msg.value, 'ETH');
    }

    
    
    
    function buyTokensWithUsdt(uint256 _tokensToBuy) public pricesMustBeSet whenNotPaused {
        
        uint256 allowance = IERC20(usdtToken).allowance(msg.sender, address(this));
        uint256 paymentRequiredInUsdt = _tokensToBuy.div(tokensPerUsd);
        require(paymentRequiredInUsdt <= allowance, 'You must approve an equal or exceeing amount of USDT tokens * price to buy those');
        
        
        IERC20(usdtToken).transferFrom(msg.sender, address(this), paymentRequiredInUsdt);
        IERC20(ovrToken).transfer(msg.sender, _tokensToBuy);
        emit TokenPurchase(msg.sender, _tokensToBuy, paymentRequiredInUsdt, 'USDT');
    }

    
    
    
    function buyTokensWithUsdc(uint256 _tokensToBuy) public pricesMustBeSet whenNotPaused {
        
        uint256 allowance = IERC20(usdcToken).allowance(msg.sender, address(this));
        uint256 paymentRequiredInUsdc = _tokensToBuy.div(tokensPerUsd);
        require(paymentRequiredInUsdc <= allowance, 'You must approve an equal or exceeing amount of USDC tokens * price to buy those');
        
        
        IERC20(usdcToken).transferFrom(msg.sender, address(this), paymentRequiredInUsdc);
        IERC20(ovrToken).transfer(msg.sender, _tokensToBuy);
        emit TokenPurchase(msg.sender, _tokensToBuy, paymentRequiredInUsdc, 'USDC');
    }

    
    
    
    function buyTokensWithDai(uint256 _tokensToBuy) public pricesMustBeSet whenNotPaused {
        
        uint256 allowance = IERC20(daiToken).allowance(msg.sender, address(this));
        uint256 paymentRequiredInDai = _tokensToBuy.div(tokensPerUsd);
        require(paymentRequiredInDai <= allowance, 'You must approve an equal or exceeing amount of DAI tokens * price to buy those');
        
        
        IERC20(daiToken).transferFrom(msg.sender, address(this), paymentRequiredInDai);
        IERC20(ovrToken).transfer(msg.sender, _tokensToBuy);
        emit TokenPurchase(msg.sender, _tokensToBuy, paymentRequiredInDai, 'DAI');
    }

    
    function extractTokens(address _tokenToExtract, uint256 _amount) public onlyOwner whenNotPaused {
        IERC20(_tokenToExtract).transfer(owner, _amount);
    }

    
    function extractEth() public onlyOwner whenNotPaused {
        owner.transfer(address(this).balance);
    }

    
    function sendTokensCreditCard(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        IERC20(ovrToken).transfer(_to, _amount);
    }

    
    function calculateHowManyTokensYouCanBuyWithEth(uint256 _tokensToBuy) public view returns(uint256) {
        return _tokensToBuy.div(tokensPerEth);
    }
}