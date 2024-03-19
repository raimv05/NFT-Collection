// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AdvancedQuickNodeNFT is ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    bool private _paused;

    mapping(uint256 => bool) private _lockedTokens;
    mapping(address => bool) private _whitelistedAddresses;
    mapping(uint256 => bytes) private _tokenMetadata; // Mapping to store encrypted metadata
    mapping(uint256 => uint256) private _tokenBundleId; // Mapping to store the bundle ID for each token
    mapping(uint256 => uint256[]) private _bundleTokens; // Mapping to store tokens in a bundle

    struct TokenBundle {
        uint256 id;
        address creator;
        address[] tokens;
    }

    TokenBundle[] private _tokenBundles;

    constructor() ERC721("QuickNode Whale", "WHS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CREATOR_ROLE, msg.sender);
        _grantRole(WHITELIST_ROLE, msg.sender); // Admin is whitelisted by default
    }

    function mint(address to, string calldata uri, bytes calldata metadata) public {
        require(!paused(), "Contract is paused"); // Check if contract is not paused
        require(_whitelistedAddresses[msg.sender], "Caller is not whitelisted"); // Check if caller is whitelisted
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenMetadata[tokenId] = metadata; // Store encrypted metadata
        _tokenIdCounter.increment();
    }

    function getMetadata(uint256 tokenId) public view returns (bytes memory) {
        return _tokenMetadata[tokenId];
    }

    function encryptMetadata(string memory metadata, bytes32 key) public pure returns (bytes memory) {
        return abi.encodePacked(keccak256(abi.encodePacked(metadata, key)));
    }

    function decryptMetadata(bytes32 key) public pure returns (string memory) {
        // Implement your decryption logic here
    }

    function grantMintPermission(address user) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        grantRole(CREATOR_ROLE, user);
        _whitelistedAddresses[user] = true;
    }

    function revokeMintPermission(address user) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        revokeRole(CREATOR_ROLE, user);
        _whitelistedAddresses[user] = false;
    }

    function addToWhitelist(address[] calldata users) public {
        require(hasRole(WHITELIST_ROLE, msg.sender), "Caller is not authorized to add to whitelist");
        for (uint256 i = 0; i < users.length; i++) {
            _whitelistedAddresses[users[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata users) public {
        require(hasRole(WHITELIST_ROLE, msg.sender), "Caller is not authorized to remove from whitelist");
        for (uint256 i = 0; i < users.length; i++) {
            _whitelistedAddresses[users[i]] = false;
        }
    }

    function createCollectionRole(bytes32 role) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _setRoleAdmin(role, DEFAULT_ADMIN_ROLE);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _paused = true;
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    function lockToken(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
        _lockedTokens[tokenId] = true;
    }

    function unlockToken(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
        _lockedTokens[tokenId] = false;
    }

    function isTokenLocked(uint256 tokenId) public view returns (bool) {
        return _lockedTokens[tokenId];
    }

    function batchTransfer(address[] calldata to, uint256[] calldata tokenIds) public {
        require(to.length == tokenIds.length, "Arrays length mismatch");
        for (uint256 i = 0; i < to.length; i++) {
            require(!_lockedTokens[tokenIds[i]], "Token is locked");
            safeTransferFrom(msg.sender, to[i], tokenIds[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function createTokenBundle(uint256[] calldata tokenIds) public returns (uint256) {
        require(tokenIds.length > 0, "Token bundle must contain at least one token");

        uint256 bundleId = _tokenBundles.length;
        _tokenBundles.push();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "You are not the owner of one of these tokens");
            require(!_lockedTokens[tokenIds[i]], "One of the tokens is locked");
            _bundleTokens[bundleId].push(tokenIds[i]);
            _tokenBundleId[tokenIds[i]] = bundleId;
        }

        return bundleId;
    }

    function getBundleTokens(uint256 bundleId) public view returns (uint256[] memory) {
        return _bundleTokens[bundleId];
    }

    function transferBundle(address to, uint256 bundleId) public {
    uint256[] memory tokenIds = getBundleTokens(bundleId);
    for (uint256 i = 0; i < tokenIds.length; i++) {
        address tokenOwner = ownerOf(tokenIds[i]);
        require(msg.sender == tokenOwner, "You are not the owner of one of these tokens");
        require(!_lockedTokens[tokenIds[i]], "One of the tokens is locked");
        safeTransferFrom(tokenOwner, to, tokenIds[i]);
    }
}
}
