pragma solidity ^0.5.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/lifecycle/Pausable.sol';
import '@openzeppelin/contracts/introspection/IERC165.sol';

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
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


/// The ICO contract to run auctions and buy OVRLands (ERC721) after winning in exchange for OVRTokens (ERC20)
/// Also handles land sells and purchases for people that want to exchange their land once they got it
contract ICO is Ownable, Pausable, IERC721Receiver {
    using SafeMath for uint256;

    // Default state is NOT_STARTED
    enum AuctionState { NOT_STARTED, ACTIVE, ENDED }

    enum LandOfferState { NOT_STARTED, ACTIVE, ACCEPTED, DECLINED, EXPIRED }

    struct Land {
        address owner;
        uint256 landToBuy;
        uint256 paid;
        uint256 lastBidTimestamp;
        AuctionState state;
        uint256 cashbackAmount;
        bool isCashbackRedeemed;
        // Marketplace functionality
        uint256 sellPrice;
        bool onSale;
        bool hasBeenRedeemed;
        uint256 lastUpdateTimestamp;
    }

    struct LandOffer {
        uint256 id; // The unique land offer identifier
        address by;
        uint256 landId;
        uint256 price;
        uint256 timestamp;
        uint256 expirationDate;
        LandOfferState state;
    }

    event AuctionStarted(address indexed lastBidder, uint256 indexed landToBuy, uint256 paid, uint256 timestamp);
    event AuctionBid(address indexed newBidder, address indexed oldBidder, uint256 indexed landToBuy, uint256 paid, uint256 timestamp);
    event WonLand(address indexed winner, uint256 indexed landId, uint256 price);
    event LandSaleStarted(address indexed owner, uint256 indexed landId, uint256 price);
    event CashbackRedeemed(uint256 indexed landId, address indexed receiver, uint256 amount, uint256 timestamp);
    // For lands that have been on sale but were removed by the owner
    event LandSaleCancelled(address indexed owner, uint256 indexed landId);
    event LandOfferCreated(uint256 indexed id, address indexed by, uint256 indexed landId, uint256 price, uint256 timestamp, uint256 expirationDate);
    event LandSold(uint256 indexed landId, address indexed oldOwner, address indexed buyer, uint256 price, uint256 timestamp);
    event LandOfferDeclined(uint256 indexed landOfferId, uint256 indexed landId);

    address public ovrToken;
    address public ovrLand;
    uint256 public initialLandBid;
    uint256 public lastLandOfferId; // A counter for setting up ids
    // The tokens that can be extracted by the owner after auctions have been won, 
    // the accomulated payments of all the winners
    uint256 public extractableTokens;
    // When the contract was created required for calculating cashbacks
    uint256 public contractCreationDate;
    // LandID => Land
    mapping (uint256 => Land) public lands;
    // User => a list of owned land ids
    mapping (address => uint256[]) public ownedLands;
    // User => how many tokens he can cashback with redeemCashback()
    mapping (address => uint256) public cashbacks;
    // LandID => All the LandOffer IDS each landId has
    mapping (uint256 => uint256[]) public landOfferIds;
    // LandOfferId => LandOffer
    mapping (uint256 => LandOffer) public landOffers;
    // Lands that have initiated the auction process can be either active or ended
    uint256[] public activeLands;

    // Lands that are on sale or have been sold previously 
    // This array is immutable meaning it won't delete already existing ids
    // because it's a very gas consuming process.
    // When a land is sold, the pointed Land id from `lands` is updated
    // There can be multiple instances of the same id inside so filter them in js
    uint256[] public landsOnSaleOrSold;

    constructor(address _ovrToken, address _ovrLand, uint256 _initialLandBid) public {
        require(_ovrToken != address(0), "The OVR ERC20 token address can't be empty");
        require(_ovrLand != address(0), "The OVR land ERC721 token address can't be empty");
        require(_initialLandBid != 0, "The initial land bid can't be zero");
        ovrToken = _ovrToken;
        ovrLand = _ovrLand;
        initialLandBid = _initialLandBid;
        contractCreationDate = now;
    }

    /// TODO test that the auctions[] is actually being updated
    /// To participate in a new or existing auction
    /// The user must first approve the right amount of OVR tokens to execute this
    /// False when the auction has ended and True when you've participated successfully
    function participateInAuction(uint256 _landId) public whenNotPaused {
        require(checkEpoch(_landId), "This land isn't available at the current epoch");

        Land storage landToBuy = lands[_landId];
        uint256 allowance = IERC20(ovrToken).allowance(msg.sender, address(this));

        if (landToBuy.state == AuctionState.ACTIVE) {
            require(now.sub(landToBuy.lastBidTimestamp) < 24 hours, 'This land auction has ended');

            // The auction for this land ID has been started
            // The next bidder must pay double the last price
            uint256 nextBid = landToBuy.paid.mul(2);
            address oldBidder = landToBuy.owner;
            uint256 oldBid = landToBuy.paid;
            require(allowance >= nextBid, 'Your allowance must equal or exceed the cost of participating in this auction');
            // Transfer new bidder's tokens
            IERC20(ovrToken).transferFrom(msg.sender, address(this), nextBid);
            // Return previous bidder's tokens
            IERC20(ovrToken).transfer(oldBidder, oldBid);
            landToBuy.owner = msg.sender;
            landToBuy.paid = nextBid;
            landToBuy.lastBidTimestamp = now;
            extractableTokens = extractableTokens.add(oldBid);
            emit AuctionBid(msg.sender, oldBidder, _landId, nextBid, now);
        } else if (landToBuy.state == AuctionState.NOT_STARTED) {
            // This is a new auction
            // Check the tokens locked in active auctions because it may happen that he has 
            // 10 approved and wants to participate in 5 auctions check that he has enough
            // to cover this auction too
            require(allowance >= initialLandBid, 'Your allowance must equal or exceed the cost of participating in this auction');
            lands[_landId] = Land(msg.sender, _landId, initialLandBid, now, AuctionState.ACTIVE, 0, false, 0, false, false, now);
            IERC20(ovrToken).transferFrom(msg.sender, address(this), initialLandBid);
            activeLands.push(_landId);
            emit AuctionStarted(msg.sender, _landId, initialLandBid, now);
        } else {
            revert('The auction has ended for this land');
        }
    }

    /// To redeem the land that you won in an auction
    function redeemWonLand(uint256 _landId) public whenNotPaused {
        Land storage land = lands[_landId];
        if (now.sub(land.lastBidTimestamp) >= 24 hours) {
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

        // Transfer the land to the user
        IERC721(ovrLand).mintLand(msg.sender, _landId);
        ownedLands[msg.sender].push(_landId);

        emit WonLand(msg.sender, _landId, land.paid);
    }

    /// To get your cashback for the buyers in the initial 9 months
    /// @param _landId The land whose cashback you want to get
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

    /// To extract the tokens that may have been sent to this contract by accident
    function extractTokens(address _tokenToExtract, uint256 _amount) public onlyOwner whenNotPaused {
        IERC20(_tokenToExtract).transfer(owner, _amount);
    }

    /// To put on sell a land you own
    /// Note: the price can be 0 to give it away for free
    /// The seller must approve the ERC721 token to the ICO contract ONLY if _onSale is true
    /// @param _onSale To indicate whether you want to put it on sale or remove it from the sale
    function putLandOnSale(uint256 _landId, uint256 _price, bool _onSale) public whenNotPaused {
        Land storage land = lands[_landId];
        require(msg.sender == land.owner, 'You must be the land owner to put it on sale');
        require(land.state == AuctionState.ENDED, 'The land auction must have been completed to put it on sale');
        if (_onSale) {
            address approved = IERC721(ovrLand).getApproved(_landId);
            require(approved == address(this), 'You must approve this contract to manage your ERC721 token');
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

    /// To buy a land on sale
    /// The buyer must approve the land price in OVR tokens to purchase it beforehand
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

    /// To offer someone to buy his land for a specific price
    /// it doesn't matter if the land is on sale or not, this offer will be sent regardless
    /// If the user already has an existing offer, override it with this new one
    /// The frontend will have to get all the offers and check those made by the same person to only keep
    /// the most recent one by looking at the timestamp
    function offerToBuyLand(uint256 _landId, uint256 _price, uint256 _expirationDate) public whenNotPaused {
        Land storage land = lands[_landId];
        uint256 allowance = IERC20(ovrToken).allowance(msg.sender, address(this));
        require(land.state == AuctionState.ENDED, 'The land auction must have been completed to send the offer to buy it');
        require(allowance >= _price, 'You must approve the right amount of OVR tokens to offer to buy it');
        require(_expirationDate > now, 'The expiration date must be larger than now');

        lastLandOfferId++;
        LandOffer memory newOffer = LandOffer(lastLandOfferId, msg.sender, _landId, _price, now, _expirationDate, LandOfferState.ACTIVE);
        landOffers[lastLandOfferId] = newOffer;
        landOfferIds[_landId].push(lastLandOfferId);

        emit LandOfferCreated(lastLandOfferId, msg.sender, _landId, _price, now, _expirationDate);
    }

    /// To respond to a buy land offer independently on whether your land is on sale or not
    /// kinda like ebay does it with the custom buy offers
    function respondToBuyOffer(uint256 _landOfferId, bool _accept) public whenNotPaused {
        LandOffer storage landOffer = landOffers[_landOfferId];
        Land storage land = lands[landOffer.landId];
        require(landOffer.state == LandOfferState.ACTIVE, 'The offer must be active to be able to respond to it');
        require(landOffer.expirationDate > now, 'The offer is expired');
        require(land.owner == msg.sender, 'You must be the owner to accept the land offer');

        if (_accept) {
            address approved = IERC721(ovrLand).getApproved(land.landToBuy);
            require(approved == address(this), 'You must approve this contract to manage your ERC721 token');
            emit LandSold(land.landToBuy, land.owner, landOffer.by, landOffer.price, now);
            IERC20(ovrToken).transferFrom(landOffer.by, land.owner, landOffer.price);
            IERC721(ovrLand).safeTransferFrom(land.owner, landOffer.by, land.landToBuy);
            landOffer.state = LandOfferState.ACCEPTED;
            land.owner = landOffer.by;
            land.onSale = false;
            land.sellPrice = 0;
        } else {
            landOffer.state = LandOfferState.DECLINED;
            emit LandOfferDeclined(_landOfferId, land.landToBuy);
        }
    }

    /// Returns an array with the the landOfferIds for a given land id
    /// you can check each independently using the array ownedLands
    function checkMyLandOffers(uint256 _landId) public view returns(uint256[] memory) {
        return landOfferIds[_landId];
    }

    /// Returns the landIds you won so you know which landIds you can redeem
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

    /// Checks if the token you want to buy is within the epoch available
    /// @return bool True if it's in a valid epoch and false if not
    function checkEpoch(uint256 _landId) public view returns(bool) {
        uint256 currentMonth = now.sub(contractCreationDate).div(30) + 1;
        // Extract the last 2 digits
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
        // Both return values work
        return this.onERC721Received.selector;
        // return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

