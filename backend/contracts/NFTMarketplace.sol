// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// internal imports for NFT openzeppelin
import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Counters.sol";
import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemSold;

    uint256 listingPrice = 0.0025 ether;

    address payable owner;

    mapping(uint256 => MarketItem) private idMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed owner,
        uint256 price,
        bool sold
    );

    event MarketItemResold(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );

    event MarketItemSold(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner of the marketplace can update listing price");
        _;
    }

    constructor() ERC721("NFTMarketplace", "MYNFT") {
        owner = payable(msg.sender);
    }

    function updateListingPrice(uint256 _listingPrice) public payable onlyOwner {
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // Let create "Create NFT Token Function"
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    // Creating market items
    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);

        emit MarketItemCreated(tokenId, msg.sender, address(this), price, false);
    }

    // Function for resell token
    function resellToken(uint256 tokenId, uint256 price) public payable{
        require(idMarketItem[tokenId].owner == msg.sender, "Only item owner can resale the token");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemResold(tokenId, msg.sender, price);
    }

    // Function createmarket sale
    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = idMarketItem[tokenId].price;

        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].seller = payable(address(0));

        _itemSold.increment();
        _transfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice);
        idMarketItem[tokenId].seller.transfer(msg.value);
        emit MarketItemSold(tokenId, msg.sender, price);
    }

    // Getting unsoled items
    function fetchUnsoledMarketItem() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemSold.current();
        uint256 unSoldItemCount = _tokenIds.current() - itemCount;
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idMarketItem[i + 1].owner == address(this)) {
                MarketItem storage currentItem = idMarketItem[i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            } 
        }
        return items;
    }

    // My Purchase items
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 myItemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                myItemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](myItemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        
        return items;
    }
    

}