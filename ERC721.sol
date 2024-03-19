// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AdvancedQuickNodeNFT is ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    // Define structure for collections
    struct Collection {
        uint256 id;
        string name;
        string description;
        address creator;
        uint256[] tokenIds;
    }

    // Mapping to store collections
    mapping(uint256 => Collection) private collections;
    uint256 private nextCollectionId = 1;

    // Maintain a list of created collection IDs
    uint256[] private createdCollectionIds;

    constructor() ERC721("QuickNode Whale", "WHS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CREATOR_ROLE, msg.sender);
    }

    function mint(address to, string calldata uri, bytes32 role) public {
        require(hasRole(role, msg.sender), "Caller is not authorized to mint in this collection");
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenIdCounter.increment();
    }

    function grantMintPermission(address user, bytes32 role) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _grantRole(role, user);
    }

    function createCollectionRole(bytes32 role) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _setRoleAdmin(role, DEFAULT_ADMIN_ROLE);
    }

    // Function to create a new collection
    function createCollection(string calldata name, string calldata description) public {
        collections[nextCollectionId] = Collection(nextCollectionId, name, description, msg.sender, new uint256[](0));
        createdCollectionIds.push(nextCollectionId); // Add the new collection ID to the list
        nextCollectionId++;
    }

    // Function to add a token to a collection
    function addToCollection(uint256 collectionId, uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
        collections[collectionId].tokenIds.push(tokenId);
    }

    // Function to transfer an entire collection to another user
    function transferCollection(address to, uint256 collectionId) public {
        require(collections[collectionId].creator == msg.sender, "You are not the creator of this collection");
        
        uint256[] memory tokenIds = collections[collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address tokenOwner = ownerOf(tokenIds[i]);
            require(tokenOwner == msg.sender, "You are not the owner of one of these tokens");
            safeTransferFrom(tokenOwner, to, tokenIds[i]);
        }
        
        delete collections[collectionId];
    }

    // Function to delete a collection
    function deleteCollection(uint256 collectionId) public {
        require(collections[collectionId].creator == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You are not authorized to delete this collection");

        // Transfer all tokens in the collection to the contract owner
        uint256[] memory tokenIds = collections[collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address tokenOwner = ownerOf(tokenIds[i]);
            safeTransferFrom(tokenOwner, ownerOf(tokenIds[i]), tokenIds[i]);

        }

        // Delete the collection
        delete collections[collectionId];
    }

    // Function to check if a collection is created
    function isCollectionCreated(uint256 collectionId) public view returns (bool) {
        return collections[collectionId].id != 0;
    }

    // Function to get the list of created collection IDs
    function getCreatedCollectionIds() public view returns (uint256[] memory) {
        return createdCollectionIds;
    }

    // Override for supportsInterface from both ERC721URIStorage and AccessControl
    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}
