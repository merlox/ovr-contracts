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

    address public ovrToken;
    address public ovrLand;
    uint256 public initialLandBid;
    // LandID => Auction
    mapping (string => Auction) public auctions;
    // User => OVR tokens locked in active actions inside this contract
    mapping (address => uint256) public userTokensInActiveAuctions;
    // User => OVR tokens that can be extracted by users after they lose an auction since they had to bid, moving their funds to this contract
    mapping (address => uint256) public redeemableTokens;

    constructor(address _ovrToken, address _ovrLand, uint256 _initialLandBid) public {
        require(_ovrToken != address(0), "The OVR ERC20 token address can't be empty");
        require(_ovrLand != address(0), "The OVR land ERC721 token address can't be empty");
        require(_initialLandBid != 0, "The initial land bid can't be zero");
        ovrToken = _ovrToken;
        ovrLand = _ovrLand;
        initialLandBid = _initialLandBid;
    }


    // The problem right now is that a person can pull their allowance whenever they want
    // So what we'll do is execute the transferFrom immediately after the bid is placed
    // Then the user will have to manually redeem his tokens if he loses the auction
    // Cuz they will be locked in the contract
    // Otherwise we run the risk of people pulling their bids right before they win
    // making them capable of inflating everybody's auction prices without buying


    /// To participate in a new or existing auction
    /// The user must first approve the right amount of OVR tokens to execute this
    /// @return bool If you were able to participate in the auction correctly or not
    /// False when the auction has ended and True when you've participated successfully
    function participateInAuction(string _landId) public whenNotPaused returns(bool) {
        Auction memory landToBuy = auctions[_landId];
        uint256 allowance = IERC20(usdtToken).allowance(msg.sender, address(this));

        if (landToBuy.state == AuctionState.ACTIVE) {
            // The auction for this land ID has been started
            uint256 nextBid = landToBuy.paid.mul(2);
            require(allowance >= nextBid, 'Your allowance must equal or exceed the cost of participating in this auction');
            userTokensInActiveAuctions // TODO Update after the transferFrom()
        } else if (landToBuy.state == AuctionState.NOT_STARTED) {
            // This is a new auction
            // Check the tokens locked in active auctions because it may happen that he has 
            // 10 approved and wants to participate in 5 auctions check that he has enough
            // to cover this auction too
            require(allowance >= initialLandBid, 'Your allowance must equal or exceed the cost of participating in this auction');
            auctions[_landId] = Auction(msg.sender, _landId, initialLandBid, now, AuctionState.ACTIVE);
            userUsedAllowance[msg.sender] += initialLandBid;
            emit AuctionStarted(msg.sender, _landId, initialLandBid, now);
        } else {
            return false;
        }

        // The auction for this land ID has not been started
        // First the user allows the 10 OVR tokens to buy the land
        // Check that he's allowed the right amount of tokens
        // Then we store the active auction in the mapping of active auctions
    }

    /// To extract the tokens that may have been sent to this contract by accident
    function extractTokens(address _tokenToExtract, uint256 _amount) public onlyOwner whenNotPaused {
        IERC20(_tokenToExtract).transfer(owner, _amount);
    }

    /// To extract the ether stored in this contract
    function extractEth() public onlyOwner whenNotPaused {
        owner.transfer(address(this).balance);
    }
}