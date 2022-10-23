// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PixelParkSale {
    /*Error*/
    error Error_AuctionNotEnded();

    /* Type decleration */
    enum Auction_State {
        Started,
        Running,
        Ended,
        Cancelled
    }
    Auction_State public auctionState = Auction_State.Ended;

    /// ----------------------------------------------------
    /// Storage variables
    /// ---------------------------------------------------

    /* Listing Variables */
    struct Asset {
        address tokenAddress;
        uint256 tokenId;
        uint8 saleType; //0 fixed price, 1 auction
        uint256 price; //initiates with bid start price in case of an auction
        uint256 fee;
        uint256 expirationTime;
        address owner;
    }

    uint256 PixelParkFee = 1e4;
    uint256 FEE_SCALE = 1e6;
    mapping(uint256 => Asset) public listings;
    uint256 public listingCounter = 0;

    /* Auction Variables */

    ///@notice Timestamp when auction was started
    address public auctioneer;

    ///@notice Timestamp when auction was started
    uint256 public startAuction;

    ///@notice Timestamp when auction was finished (24h after starting)
    uint256 public endAuction;

    ///@notice Price in ether of the current winning bid
    uint256 public bidPrice;

    ///@notice Address of the current winner bidder
    address public bidder;

    ///@notice Track when someone made a bid
    bool private isBidded = false;

    ///@notice Time Auction will last
    uint256 public AUCTION_DURATION;

    ///@notice Min price for NFT
    uint256 public MIN_PRICE;

    ///@notice Min delta between 2 bids
    uint256 public MIN_BID;

    constructor() {
        auctioneer = payable(msg.sender);
    }

    /* Events */
    event ListedForSale();
    event LaunchAuction(uint256 StartTimestamp, uint256 EndTimestamp);
    event Bid(address indexed BidderAddress, uint256 BidPrice);

    /*Modifiers*/
    modifier notOwner() {
        require(
            msg.sender != auctioneer,
            "Owner cannot bid and only owner can execute auction"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == auctioneer,
            "Owner cannot bid and only owner has access of this"
        );
        _;
    }

    function listForSale(
        address tokenAddress,
        uint256 tokenId,
        uint8 saleType,
        uint256 _price,
        uint256 _fee,
        uint256 _duration
    ) public returns (uint256) {
        Asset memory _asset = Asset(
            tokenAddress,
            tokenId,
            saleType,
            _price,
            _fee,
            _duration,
            msg.sender
        );
        listings[listingCounter] = _asset;
        listingCounter++;
        return listingCounter - 1;
    }

    function buyAsset(uint256 listingId) public payable {
        if (listings[listingId].saleType == 1) {
            require(
                listings[listingId].expirationTime >= block.timestamp,
                "auction time ended"
            );
        }
        payable(listings[listingId].owner).transfer(listings[listingId].price);
        IERC721(listings[listingId].tokenAddress).transferFrom(
            listings[listingId].owner,
            msg.sender,
            listings[listingId].tokenId
        );
    }

    /// ------------------------------------------------------
    /// Auctionerr action
    /// ------------------------------------------------------

    function executeAuction(uint256 listingId) public payable onlyOwner {
        require(listings[listingId].saleType == 1, "Not an auction listing");
        auctionState = Auction_State.Running;
        startAuction = block.timestamp;
        endAuction = startAuction + AUCTION_DURATION;

        payable(listings[listingId].owner).transfer(listings[listingId].price);

        IERC721(listings[listingId].tokenAddress).transferFrom(
            listings[listingId].owner,
            msg.sender,
            listings[listingId].tokenId
        );
    }

    function cancelAuction() public onlyOwner {
        auctionState = Auction_State.Cancelled;
    }

    function finalizeAuction(uint256 listingId) public payable {
        require(
            auctionState == Auction_State.Cancelled ||
                block.timestamp > endAuction
        );

        require(msg.sender == auctioneer || msg.sender == listings[listingId].owner);
    }

    /// ------------------------------------------------------
    /// Users actions
    /// ------------------------------------------------------

    function placeBid(uint256 listingId, uint256 _bidPrice)
        public
        payable
        notOwner
    {
        require(listings[listingId].saleType == 1, "Not an auction listing");
        require(
            _bidPrice > listings[listingId].price,
            "bid amount less than listing price"
        );
        listings[listingId].price = _bidPrice;
    }

    // function executeAuction(uint256 listingId) onlyOwner public payable {
    //     require(listings[listingId].saleType == 1, "Not an auction listing");
    //     payable(listings[listingId].owner).transfer(listings[listingId].price);
    //     IERC721(listings[listingId].tokenAddress).transferFrom(
    //         listings[listingId].owner,
    //         msg.sender,
    //         listings[listingId].tokenId
    //     );
    // }

    // function placeBid(uint256 listingId, uint256 _bidAmount) public payable {
    //     require(listings[listingId].saleType == 1, "Not an auction listing");
    //     require(
    //         _bidAmount > listings[listingId].price,
    //         "bid amount less than max bid"
    //     );
    //     listings[listingId].price = _bidAmount;
    // }

    // function unlockAuctionAsset(){

    // }

    receive() external payable {}
}
