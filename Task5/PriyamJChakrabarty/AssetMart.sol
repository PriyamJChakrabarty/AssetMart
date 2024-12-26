// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract AssetMart is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address payable owner;
    uint256 listingPrice = 0.025 ether;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool isListed;
        string tokenURI;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event ListingSuccess(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool isListed
    );

    constructor() ERC721("AssetMart", "AM") {
        owner = payable(msg.sender);
    }

    function createToken(string memory tokenURI, uint256 price) public payable {
        require(price > 0, "Price must be at least 1 wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        transferFrom(msg.sender, address(this), newTokenId);

        _createMarketItem(newTokenId, price, tokenURI);

        emit ListingSuccess(newTokenId, msg.sender, address(this), price, true);
    }

    function _createMarketItem(uint256 tokenId, uint256 price, string memory tokenURI) private {
        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            true,
            tokenURI
        );
    }

    function getAllNFTs() external view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 activeCount = 0;

        // Count active listings
        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (idToMarketItem[i].isListed) {
                activeCount++;
            }
        }

        // Create array of active listings
        MarketItem[] memory activeItems = new MarketItem[](activeCount);
        uint256 currentIndex = 0;

        // Populate active listings array
        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (idToMarketItem[i].isListed) {
                activeItems[currentIndex] = idToMarketItem[i];
                currentIndex++;
            }
        }

        return activeItems;
    }
    

    // 1. Go through all NFTs in the marketplace.
    // 2. Check if the NFT is still listed (active).
    // 3. Check if the seller is the currently logged-in user (msg.sender).
    // 4. If both conditions are true, count it and add it to the result.
    // 5. Return the list of NFTs owned by the user and still for sale.

    
    function getMyNFTs() external view returns (MarketItem[] memory) {
    

    uint256 totalItemCount = _tokenIds.current();
    uint256 ownedActiveCount = 0;

    for (uint256 i = 1; i <= totalItemCount; i++) {
        if (idToMarketItem[i].isListed && idToMarketItem[i].seller == msg.sender) {
            ownedActiveCount++;
        }
    }

    MarketItem[] memory ownedActiveItems = new MarketItem[](ownedActiveCount);
    uint256 currentIndex = 0;

    for (uint256 i = 1; i <= totalItemCount; i++) {
        if (idToMarketItem[i].isListed && idToMarketItem[i].seller == msg.sender) {
            ownedActiveItems[currentIndex] = idToMarketItem[i];
            currentIndex++;
        }
    }

    return ownedActiveItems;
    }

}

