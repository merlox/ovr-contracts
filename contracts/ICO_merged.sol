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

contract IERC721Receiver {
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
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

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;

    function mintLand(address to, uint256 OVRLandID) public returns (bool);
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

contract ICO is Ownable, Pausable, IERC721Receiver {
    using SafeMath for uint256;

    
    enum AuctionState { NOT_STARTED, ACTIVE, ENDED }

    enum LandOfferState { NOT_STARTED, ACTIVE, ACCEPTED, DECLINED, EXPIRED, CANCELLED }

    struct Land {
        address payable owner;
        uint256 landToBuy;
        uint256 paid;
        uint256 lastBidTimestamp;
        AuctionState state;
        uint256 cashbackAmount;
        bool isCashbackRedeemed;
        
        uint256 sellPrice;
        bool onSale;
        bool hasBeenRedeemed;
        uint256 lastUpdateTimestamp;
        uint256 paidWith;
    }

    struct LandOffer {
        uint256 id; 
        address payable by;
        uint256 group; 
        uint256 landId;
        uint256 price;
        uint256 timestamp;
        uint256 expirationDate;
        LandOfferState state;
    }

    event WonLand(address indexed winner, uint256 indexed landId, uint256 price);
    event LandSaleStarted(address indexed owner, uint256 indexed landId, uint256 price);
    event CashbackRedeemed(uint256 indexed landId, address indexed receiver, uint256 amount, uint256 timestamp);
    
    event LandSaleCancelled(address indexed owner, uint256 indexed landId);
    event LandOfferCreated(uint256 indexed id, address indexed by, uint256 indexed landId, uint256 price, uint256 timestamp, uint256 expirationDate);
    event LandSold(uint256 indexed landId, address indexed oldOwner, address indexed buyer, uint256 price, uint256 timestamp);
    event LandOfferDeclined(uint256 indexed landOfferId, uint256 indexed landId);
    event LandOfferCancelled(uint256 indexed offerId);

    address public ovrToken;
    address public ovrLand;
    address public tokenBuy;
    address public dai;
    address public usdt;
    address public usdc;
    uint256 public tokensPerUsd;
    uint256 public tokensPerEth;

    address public approved;

    uint256 public initialLandBid;
    uint256 public lastLandOfferId; 
    
    uint256 public contractCreationDate;
    
    mapping (uint256 => Land) public lands;
    
    mapping (address => uint256[]) public ownedLands;
    
    mapping (address => uint256) public cashbacks;
    
    mapping (uint256 => uint256[]) public landOfferIds;
    
    mapping (uint256 => LandOffer) public landOffers;
    
    mapping (uint256 => uint256) public groupCounters;
    
    uint256[] public activeLands;
    uint256 public auctionLandDuration = 24 hours; 

    
    
    
    
    
    uint256[] public landsOnSaleOrSold;

    modifier onlyApproved {
        require(msg.sender == approved);
        _;
    }

    constructor(address _ovrToken, address _ovrLand, address _tokenBuy, uint256 _initialLandBid) public {
        require(_ovrToken != address(0), "The OVR ERC20 token address can't be empty");
        require(_ovrLand != address(0), "The OVR land ERC721 token address can't be empty");
        require(_tokenBuy != address(0), "The TokenBuy contract address can't be empty");
        require(_initialLandBid != 0, "The initial land bid can't be zero");
        ovrToken = _ovrToken;
        ovrLand = _ovrLand;
        tokenBuy = _tokenBuy;
        initialLandBid = _initialLandBid;
        contractCreationDate = now;
    }

    function setApproved(address _approved) public onlyOwner {
        approved = _approved;
    }

    
    function setAuctionLandDuration(uint256 _time) public onlyOwner {
        require(_time > 0, "The auction duration can't be zero");
        auctionLandDuration = _time;
    }

    
    function redeemWonLand(uint256 _landId) public whenNotPaused {
        Land storage land = lands[_landId];
        if (now.sub(land.lastBidTimestamp) >= auctionLandDuration) {
            land.state = AuctionState.ENDED;
        }
        require(land.state == AuctionState.ENDED, "You can't redeem this land until its auction is finished");
        require(land.owner == msg.sender, 'You must be the land winner to redeem it');
        uint256 cashbackPercentage;
        uint256 monthPurchasedSinceBeginning = now.sub(contractCreationDate).div(30 days) + 1;
        if (monthPurchasedSinceBeginning == 1) {
            cashbackPercentage = 95;
        } else if (monthPurchasedSinceBeginning == 2) {
            cashbackPercentage = 85;
        } else if (monthPurchasedSinceBeginning == 3) {
            cashbackPercentage = 75;
        } else if (monthPurchasedSinceBeginning == 4) {
            cashbackPercentage = 65;
        } else if (monthPurchasedSinceBeginning == 5) {
            cashbackPercentage = 55;
        } else if (monthPurchasedSinceBeginning == 6) {
            cashbackPercentage = 45;
        } else if (monthPurchasedSinceBeginning == 7) {
            cashbackPercentage = 35;
        } else if (monthPurchasedSinceBeginning == 8) {
            cashbackPercentage = 25;
        } else if (monthPurchasedSinceBeginning == 9) {
            cashbackPercentage = 15;
        } else {
            cashbackPercentage = 0;
        }
        uint256 cashback = land.paid.mul(cashbackPercentage).div(100);
        cashbacks[msg.sender] = cashbacks[msg.sender].add(cashback);
        land.cashbackAmount = cashback;
        land.hasBeenRedeemed = true;
        
        IERC721(ovrLand).mintLand(msg.sender, _landId);
        ownedLands[msg.sender].push(_landId);
        emit WonLand(msg.sender, _landId, land.paid);
    }

    function redeemBulkLands(uint256[] memory _landIds) public whenNotPaused {
        for (uint256 i = 0; i < _landIds.length; i++) {
            redeemWonLand(_landIds[i]);
        }
    }

    
    
    function redeemCashback(uint256 _landId) public whenNotPaused {
        Land storage land = lands[_landId];
        require(!land.isCashbackRedeemed, 'The cashback has already been redeemed for this land');
        require(land.hasBeenRedeemed, 'The land must be redeemed before getting its cashback');
        require(land.owner == msg.sender, 'You must be the land owner to redeem its cashback');
        require(now.sub(land.lastBidTimestamp) >= 30 days, "You can't redeem a cashback before 30 days");
        uint256 tempAmount = land.cashbackAmount;
        cashbacks[msg.sender] = cashbacks[msg.sender].sub(land.cashbackAmount);
        land.isCashbackRedeemed = true;
        land.cashbackAmount = 0;

        IERC20(ovrToken).transfer(msg.sender, tempAmount);
        emit CashbackRedeemed(_landId, msg.sender, land.cashbackAmount, now);
    }

    
    function extractTokens(address _tokenToExtract, uint256 _amount) public onlyOwner whenNotPaused {
        IERC20(_tokenToExtract).transfer(owner, _amount);
    }

    function extractEth() public onlyOwner whenNotPaused {
        owner.transfer(address(this).balance);
    }

    
    
    
    
    function putLandOnSale(uint256 _landId, uint256 _price, bool _onSale) public whenNotPaused {
        Land storage land = lands[_landId];
        require(msg.sender == land.owner, 'You must be the land owner to put it on sale');
        require(land.state == AuctionState.ENDED, 'The land auction must have been completed to put it on sale');
        if (_onSale) {
            address _approved = IERC721(ovrLand).getApproved(_landId);
            require(_approved == address(this), 'You must approve this contract to manage your ERC721 token');
        }
        land.onSale = _onSale;
        land.sellPrice = _price;
        land.lastUpdateTimestamp = now;
        landsOnSaleOrSold.push(_landId);
        if (_onSale) {
            IERC721(ovrLand).safeTransferFrom(msg.sender, address(this), _landId);
            emit LandSaleStarted(land.owner, _landId, _price);
        } else {
            IERC721(ovrLand).safeTransferFrom(address(this), msg.sender, _landId);
            emit LandSaleCancelled(land.owner, _landId);
        }
    }

    
    
    function buyLand(uint256 _landId) public whenNotPaused {
        Land storage land = lands[_landId];
        address oldOwner = land.owner;
        uint256 salePrice = land.sellPrice;
        uint256 allowance = IERC20(ovrToken).allowance(msg.sender, address(this));
        require(land.onSale, 'The land must be on sale to buy it');
        require(allowance >= land.sellPrice, 'You must approve the right amount of OVR tokens to buy this land');
        require(land.state == AuctionState.ENDED, 'The land auction must have been completed to buy it');
        land.owner = msg.sender;
        land.onSale = false;
        land.sellPrice = 0;
        land.lastUpdateTimestamp = now;
        IERC20(ovrToken).transferFrom(msg.sender, oldOwner, salePrice);
        IERC721(ovrLand).safeTransferFrom(address(this), msg.sender, _landId);
        emit LandSold(_landId, oldOwner, msg.sender, salePrice, now);
    }

    
    
    
    
    
    function offerToBuyLand(uint256 _landId, uint256 _price, uint256 _expirationDate) public whenNotPaused {
        Land storage land = lands[_landId];
        uint256 allowance = IERC20(ovrToken).allowance(msg.sender, address(this));
        require(land.state == AuctionState.ENDED, 'The land auction must have been completed to send the offer to buy it');
        require(allowance >= _price, 'You must approve the right amount of OVR tokens to offer to buy it');
        require(_expirationDate > now, 'The expiration date must be larger than now');

        lastLandOfferId++;
        LandOffer memory newOffer = LandOffer(lastLandOfferId, msg.sender, groupCounters[_landId], _landId, _price, now, _expirationDate, LandOfferState.ACTIVE);
        landOffers[lastLandOfferId] = newOffer;
        landOfferIds[_landId].push(lastLandOfferId);

        emit LandOfferCreated(lastLandOfferId, msg.sender, _landId, _price, now, _expirationDate);
    }

    
    function cancelBuyOffer(uint256 _offerId) public whenNotPaused {
        LandOffer storage offer = landOffers[_offerId];
        require(msg.sender == offer.by, 'You must be the owner to cancel the buy offer');
        offer.state = LandOfferState.CANCELLED;
        
        emit LandOfferCancelled(_offerId);
    }

    
    
    function respondToBuyOffer(uint256 _landOfferId, bool _accept) public whenNotPaused {
        LandOffer storage landOffer = landOffers[_landOfferId];
        Land storage land = lands[landOffer.landId];
        require(landOffer.state == LandOfferState.ACTIVE, 'The offer must be active to be able to respond to it');
        require(landOffer.expirationDate > now, 'The offer is expired');
        require(land.owner == msg.sender, 'You must be the owner to accept the land offer');

        if (_accept) {
            address _approved = IERC721(ovrLand).getApproved(land.landToBuy);
            require(_approved == address(this), 'You must approve this contract to manage your ERC721 token');
            emit LandSold(land.landToBuy, land.owner, landOffer.by, landOffer.price, now);
            IERC20(ovrToken).transferFrom(landOffer.by, land.owner, landOffer.price);
            IERC721(ovrLand).safeTransferFrom(land.owner, landOffer.by, land.landToBuy);
            landOffer.state = LandOfferState.ACCEPTED;
            land.owner = landOffer.by;
            land.onSale = false;
            land.sellPrice = 0;
            groupCounters[landOffer.landId]++;
        } else {
            landOffer.state = LandOfferState.DECLINED;
            emit LandOfferDeclined(_landOfferId, land.landToBuy);
        }
    }

    
    function setLands(
        address payable owner, 
        uint256 landToBuy,
        uint256 paid,
        AuctionState state,
        uint256 paidWith
    ) public onlyApproved {
        lands[landToBuy] = Land(owner, landToBuy, paid, now, state, 0, false, 0, false, false, now, paidWith);
    }

    function pushActiveLand(uint256 _landId) public onlyApproved {
        activeLands.push(_landId);
    }

    
    
    function checkMyLandOffers(uint256 _landId) public view returns(uint256[] memory) {
        return landOfferIds[_landId];
    }

    
    function checkWonLands() public view returns(uint256[] memory) {
        uint256[] memory result;
        uint256 counter = 0;
        for(uint256 i = 0; i < activeLands.length; i++) {
            uint256 landId = activeLands[i];
            if (lands[landId].state == AuctionState.ENDED && lands[landId].owner == msg.sender) {
                result[counter] = landId;
                counter = counter.add(1);
            }
        }
        return result;
    }

    
    
    function checkEpoch(uint256 _landId) public view returns(bool) {
        uint256 currentMonth = now.sub(contractCreationDate).div(30) + 1;
        
        uint256 landIdDigits = _landId % 100;
        if (currentMonth == 1) {
            if (landIdDigits <= 17) {
                return true;
            } else {
                return false;
            }
        } else if (currentMonth == 2) {
            if (landIdDigits > 17 && landIdDigits <= 35) {
                return true;
            } else {
                return false;
            }
        } else if (currentMonth == 3) {
            if (landIdDigits > 35 && landIdDigits <= 53) {
                return true;
            } else {
                return false;
            }
        } else if (currentMonth == 4) {
            if (landIdDigits > 53 && landIdDigits <= 70) {
                return true;
            } else {
                return false;
            }
        } else if (currentMonth == 5) {
            if (landIdDigits > 70 && landIdDigits <= 88) {
                return true;
            } else {
                return false;
            }
        } else if (currentMonth == 6) {
            if (landIdDigits > 88 && landIdDigits <= 99) {
                return true;
            } else {
                return false;
            }
        }
        
        return true;
    }

    function getActiveLands() public view returns(uint256[] memory) {
        return activeLands;
    }

    function getLandsOnSaleOrSold() public view returns(uint256[] memory) {
        return landsOnSaleOrSold;
    }

    function getLandOffers(uint256 _landId) public view returns(uint256[] memory) {
        return landOfferIds[_landId];
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        
        return this.onERC721Received.selector;
        
    }
}

contract ICOParticipate is Pausable {
    using SafeMath for uint256;

    event AuctionStarted(address indexed lastBidder, uint256 indexed landToBuy, uint256 paid, uint256 timestamp);
    event AuctionBid(address indexed newBidder, address indexed oldBidder, uint256 indexed landToBuy, uint256 paid, uint256 timestamp);

    address public ovrLand;
    address public tokenBuy;
    IERC20 public ovrToken;
    IERC20 public dai;
    IERC20 public usdt;
    IERC20 public usdc;
    uint256 public tokensPerUsd;
    uint256 public tokensPerEth;
    ICO public ico;

    constructor (address _ico) public {
        ico = ICO(_ico);
        ovrLand = ico.ovrLand();
        tokenBuy = ico.tokenBuy();
        ovrToken = IERC20(ico.ovrToken());
        dai = IERC20(TokenBuyInterface(tokenBuy).daiToken());
        usdt = IERC20(TokenBuyInterface(tokenBuy).usdtToken());
        usdc = IERC20(TokenBuyInterface(tokenBuy).usdcToken());
        updateTokenBuyValues();
    }

    function updateTokenBuyValues() public {
        tokensPerUsd = TokenBuyInterface(tokenBuy).tokensPerUsd();
        tokensPerEth = TokenBuyInterface(tokenBuy).tokensPerEth();
    }


    
event MyTest(string indexed, ICO.AuctionState indexed, ICO.AuctionState, bool indexed);

function test(uint256 _landId) public {
    (,,, uint256 lastBidTimestamp, ICO.AuctionState state,,,,,,,) = ico.lands(_landId);
    emit MyTest("a", state, ICO.AuctionState.NOT_STARTED, state == ICO.AuctionState.NOT_STARTED);
}
    
    function participate (uint256 _token, uint256 _bid, uint256 _landId) public payable whenNotPaused {
        
        
        
        

        
        
        (,,, uint256 lastBidTimestamp, ICO.AuctionState state,,,,,,,) = ico.lands(_landId);
        emit MyTest("AAAA", state, ICO.AuctionState.ENDED, state == ICO.AuctionState.ENDED);
        
        
        if (state == ICO.AuctionState.NOT_STARTED) {
            emit MyTest("NOTSTARTED", state, ICO.AuctionState.NOT_STARTED, state == ICO.AuctionState.NOT_STARTED);
        } else if (state == ICO.AuctionState.ACTIVE) {
            emit MyTest("ACTIVE", state, ICO.AuctionState.ACTIVE, state == ICO.AuctionState.ACTIVE);
        } else if (state == ICO.AuctionState.ENDED) {
            emit MyTest("ENDED", state, ICO.AuctionState.ENDED, state == ICO.AuctionState.ENDED);
        } else {
            emit MyTest("OTHER", state, ICO.AuctionState.ENDED, state == ICO.AuctionState.ENDED);
        }
    }


    function participateActiveAuction (uint256 _token, uint256 _bid, uint256 _landId) internal whenNotPaused {
        (address payable oldBidder,, uint256 oldBid,, ICO.AuctionState state,,,,,,, uint256 paidWith) = ico.lands(_landId);
        require(_bid >= oldBid.mul(2), 'Your bid must be equal or larger than double the previous one');

        
        if (paidWith == 0) {
            oldBidder.transfer(oldBid.div(tokensPerEth));
        } else if (paidWith == 1) {
            dai.transfer(oldBidder, oldBid.div(tokensPerUsd));
        } else if (paidWith == 2) {
            usdt.transfer(oldBidder, oldBid.div(tokensPerUsd));
        } else if (paidWith == 3) {
            usdc.transfer(oldBidder, oldBid.div(tokensPerUsd));
        } else if (paidWith == 4) {
            ovrToken.transfer(oldBidder, oldBid);
        }

        ico.setLands(msg.sender, _landId, _bid, state, _token);
        emit AuctionBid(msg.sender, oldBidder, _landId, _bid, now);
    }

    function participateNewAuction (uint256 _token, uint256 _bid, uint256 _landId) internal whenNotPaused {
        ico.setLands(msg.sender, _landId, _bid, ICO.AuctionState.ACTIVE, _token);
        if (_token == 1) {
            dai.transferFrom(msg.sender, address(this), _bid.div(tokensPerUsd));
        } else if (_token == 2) {
            usdt.transferFrom(msg.sender, address(this), _bid.div(tokensPerUsd));
        } else if (_token == 3) {
            usdc.transferFrom(msg.sender, address(this), _bid.div(tokensPerUsd));
        } else if (_token == 4) {
            ovrToken.transferFrom(msg.sender, address(this), _bid);
        }
        ico.pushActiveLand(_landId);
        emit AuctionStarted(msg.sender, _landId, _bid, now);
    }
}