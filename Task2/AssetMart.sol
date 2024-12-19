// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract AssetMart is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; // Keeps track of the total number of tokens created

    address payable public owner; // The address of the person who deployed the contract
    uint256 public listingFee = 0.01 ether; // Fee to list an NFT on the marketplace

    // This structure represents an item listed on the marketplace
    struct MarketItem {
        uint256 tokenId; // The unique ID of the NFT
        address payable seller; // The address of the person selling the NFT
        address payable owner; // The current owner of the NFT (initially, this contract)
        uint256 price; // The price set for the NFT
        bool isListed; // Whether the NFT is currently listed for sale
    }

    // A mapping to store all the market items using their token ID as the key
    mapping(uint256 => MarketItem) public marketItems;

    // Events to notify when an NFT is listed or transferred
    event ListingSuccess(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool isListed
    );

    event TokenTransfer(
        uint256 indexed tokenId,
        address from,
        address to
    );

    // The constructor sets the person deploying the contract as the owner
    constructor() ERC721("AssetMart", "AM") {
        owner = payable(msg.sender);
    }

    /**
     * @notice Create a new NFT and list it on the marketplace.
     * @param tokenURI The URL pointing to the NFT's metadata (usually on IPFS).
     * @param price The price at which the NFT will be listed.
     * @return newTokenId The unique ID of the newly created NFT.
     */
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint256) {
        require(price > 0, "Price must be greater than zero"); // Make sure the price is valid
        require(msg.value == listingFee, "Listing fee must be paid"); // Ensure the listing fee is paid

        _tokenIds.increment(); // Increment the counter to get a unique token ID
        uint256 newTokenId = _tokenIds.current(); // Assign the new token ID

        _mint(msg.sender, newTokenId); // Mint the NFT and assign it to the sender
        _setTokenURI(newTokenId, tokenURI); // Attach the metadata URI to the NFT

        _createMarketItem(newTokenId, price); // Register the NFT as a market item

        // Move the NFT from the sender to this contract for listing
        transferFrom(msg.sender, address(this), newTokenId);

        // Notify that the NFT was transferred successfully
        emit TokenTransfer(newTokenId, msg.sender, address(this));

        return newTokenId; // Return the unique ID of the new NFT
    }

    /**
     * @notice Create a market item and save its details.
     * @param tokenId The unique ID of the NFT.
     * @param price The price at which the NFT will be sold.
     */
    function _createMarketItem(uint256 tokenId, uint256 price) private {
        marketItems[tokenId] = MarketItem(
            tokenId, // Token ID of the NFT
            payable(msg.sender), // The person selling the NFT
            payable(address(this)), // Initially owned by the contract
            price, // Price of the NFT
            true // Mark it as listed
        );

        // Notify that the item was successfully listed
        emit ListingSuccess(tokenId, msg.sender, address(this), price, true);
    }

    /**
     * @notice Get the listing fee required to list an NFT.
     * @return The listing fee in wei (smallest unit of Ether).
     */
    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    /**
     * @notice Fetch the details of a market item using its token ID.
     * @param tokenId The unique ID of the NFT.
     * @return The details of the market item.
     */
    function fetchMarketItem(uint256 tokenId) public view returns (MarketItem memory) {
        return marketItems[tokenId];
    }
}
