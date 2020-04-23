pragma solidity ^0.5.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/lifecycle/Pausable.sol';

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
contract ICO is Ownable, Pausable {
    using SafeMath for uint256;

    // Default state is NOT_STARTED
    enum AuctionState { NOT_STARTED, ACTIVE, ENDED }

    struct Auction {
        address lastBidder;
        string landToBuy;
        uint256 paid;
        uint256 lastBidTimestamp;
        AuctionState state;
    }

    event AuctionStarted(address indexed lastBidder, string indexed landToBuy, uint256 paid, uint256 timestamp);
    event AuctionBid(address indexed newBidder, address indexed oldBidder, string indexed landToBuy, uint256 paid, uint256 timestamp);
    event WonLand(address indexed winner, string indexed landId, uint256 price);

    address public ovrToken;
    address public ovrLand;
    uint256 public initialLandBid;
    // The tokens that can be extracted by the owner after auctions have been won, 
    // the accomulated payments of all the winners
    uint256 public extractableTokens;
    // When the contract was created required for calculating cashbacks
    uint256 public contractCreationDate;
    // LandID => Auction
    mapping (string => Auction) public auctions;
    // User => OVR tokens locked in active actions inside this contract
    mapping (address => uint256) public userTokensInActiveAuctions;
    // User => a list of owned land ids
    mapping (address => string[]) public ownedLands;
    // User => how many tokens he can cashback with redeemCashback()
    mappings (address => uint256) public cashbacks;
    string[] public activeLands;

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
    /// @return bool If you were able to participate in the auction correctly or not
    /// False when the auction has ended and True when you've participated successfully
    function participateInAuction(string _landId) public whenNotPaused returns(bool) {
        Auction storage landToBuy = auctions[_landId];
        uint256 allowance = IERC20(usdtToken).allowance(msg.sender, address(this));

        if (landToBuy.state == AuctionState.ACTIVE) {
            // The auction for this land ID has been started
            // The next bidder must pay double the last price
            uint256 nextBid = landToBuy.paid.mul(2);
            address oldBidder = landToBuy.lastBidder;
            uint256 oldBid = landToBuy.paid;
            require(allowance >= nextBid, 'Your allowance must equal or exceed the cost of participating in this auction');
            userTokensInActiveAuctions[oldBidder] = userTokensInActiveAuctions[oldBidder].sub(oldBid);
            // Transfer new bidder's tokens
            IERC20(ovrToken).transferFrom(msg.sender, address(this), nextBid);
            // Return previous bidder's tokens
            IERC20(ovrToken).transfer(oldBidder, oldBid);
            landToBuy.lastBidder = msg.sender;
            landToBuy.paid = nextBid;
            landToBuy.lastBidTimestamp = now;
            extractableTokens = extractableTokens.add(oldBid);
            emit AuctionBid(msg.sender, oldBidder, _landId, nextBid, now);
            return true;
        } else if (landToBuy.state == AuctionState.NOT_STARTED) {
            // This is a new auction
            // Check the tokens locked in active auctions because it may happen that he has 
            // 10 approved and wants to participate in 5 auctions check that he has enough
            // to cover this auction too
            require(allowance >= initialLandBid, 'Your allowance must equal or exceed the cost of participating in this auction');
            auctions[_landId] = Auction(msg.sender, _landId, initialLandBid, now, AuctionState.ACTIVE);
            userUsedAllowance[msg.sender] = userUsedAllowance[msg.sender].add(initialLandBid);
            activeLands.push(_landId);
            emit AuctionStarted(msg.sender, _landId, initialLandBid, now);
            return true;
        } else {
            return false;
        }
    }

    /// To redeem the land that you won in an auction
    function redeemWonLand(string _landId) public whenNotPaused {
        Auction memory auction = auctions[_landId];
        if (now.sub(auction.lastBidTimestamp) > 24 hours) {
            auctions[_landId].state = AuctionState.ENDED;
        }
        require(auction.state != AuctionState.ENDED, "You can't redeem this land until its auction is finished");
        uint256 cashbackPercentage;
        uint256 monthPurchasedSinceBeginning = now.sub(contractCreationDate).div(30 days);
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
        uint256 cashback = auction.price.mul(cashbackPercentage).div(100);
        cashbacks[msg.sender] = cashbacks[msg.sender].add(cashback);

        // Transfer the land to the user
        // TODO Test this to make sure that the parameters are correct cuz it may need to be changed I'm not sure how it works
        IERC721(ovrLand).safeTransferFrom(owner, msg.sender, _landId);
        ownedLands[msg.sender].push(_landId);

        emit WonLand(msg.sender, _landId, auction.price);
    }

    // TODO create the epoch functionality

    /// To get your cashback for the buyers in the initial 9 months
    function redeemCashback() public whenNotPaused {
        uint256 tempCashback = cashbacks[msg.sender];
        cashbacks[msg.sender] = 0;
        IERC20(ovrToken).transfer(msg.sender, tempCashback);
    }

    /// To extract the tokens that may have been sent to this contract by accident
    function extractTokens(address _tokenToExtract, uint256 _amount) public onlyOwner whenNotPaused {
        IERC20(_tokenToExtract).transfer(owner, _amount);
    }

    /// To extract the ether stored in this contract
    function extractEth() public onlyOwner whenNotPaused {
        owner.transfer(address(this).balance);
    }

    /// Returns the landIds you won so you know which landIds you can redeem
    function checkWonLands() public view returns(string[]) {
        string[] memory result;
        uint256 counter = 0;
        for(uint256 i = 0; i < activeLands.length; i++) {
            string landId = activeLands[i];
            if (auctions[landId].state == AuctionState.ENDED && auctions[landId].lastBidder == msg.sender) {
                result[counter] = landId;
                counter = counter.add(1);
            }
        }
        return result;
    }
}