// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// ----------------------------------------------------------------------------
// BaseMarketPlace - KDZ NFT MarketPlace
//
// Copyright (c) 2022 Kenny Dizi
//
// ----------------------------------------------------------------------------

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./KDZTokens.sol";

interface INFToken {
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenId) external returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract BaseMarketPlace is Context, AccessControlEnumerable {
    // Non-Fungible Token Contract
    INFToken internal NFTContract;

    /**
     * @dev Manage tokenId with price and sale state
     */
    struct KDZTokenStruct {
        uint256 price;
        bool forSale;
        address payable currentlyOwner;
    }

    /**
     * @dev Map tokenId link with sale state
     */
    mapping(uint256 => KDZTokenStruct) _kdzTokens;

    // init contract by passing NFT contract address
    constructor(address NFTAddress) {
        // setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        NFTContract = INFToken(NFTAddress);
    }

    /**
     * @dev Create new token management state
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     */
    function createNewTokenState(
        uint256 _tokenId,
        uint256 _tokenPrice,
        bool _forSale
    ) public virtual {
        // require that token should existent
        require(
            NFTContract.exists(_tokenId),
            "ETH2NFTMarketPlace: Interacting with nonexistent token"
        );

        // get the token's owner
        address tokenOwner = NFTContract.ownerOf(_tokenId);

        // require token state doesn't existent
        require(
            tokenOwner == _msgSender() ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ETH2NFTMarketPlace: Caller have to be token owner or Admin role"
        );

        // create new token state
        KDZTokenStruct memory newTokenState = KDZTokenStruct(
            _tokenPrice,
            _forSale,
            payable(tokenOwner)
        );

        // assign to collection
        _setNewTokenState(_tokenId, newTokenState);
    }

    /**
     * @dev Mapping tokenId with sale management side.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     */
    function _setNewTokenState(
        uint256 _tokenId,
        KDZTokenStruct memory _newTokenState
    ) internal virtual {
        // require that token should existent
        require(
            NFTContract.exists(_tokenId),
            "ETH2NFTMarketPlace: Interacting with nonexistent token"
        );

        // get the token's owner
        address tokenOwner = NFTContract.ownerOf(_tokenId);

        // check that token's owner should be equal to the caller of the function
        require(
            tokenOwner == _msgSender() ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ETH2NFTMarketPlace: Caller must be token owner or admin"
        );

        // mapping tokenId and token sale management
        _kdzTokens[_tokenId] = _newTokenState;
    }

    /**
     * @dev Toggle sale state of the tokenId
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function toggleForSale(uint256 _tokenId) public virtual {
        // require caller of the function is not an empty address
        require(
            _msgSender() != address(0),
            "ETH2NFTMarketPlace: Caller of the function haven't been empty address"
        );

        // require that token should exist
        require(
            NFTContract.exists(_tokenId),
            "ETH2NFTMarketPlace: Toggle sale state of nonexistent token"
        );

        // get the token's owner
        address tokenOwner = NFTContract.ownerOf(_tokenId);

        // check that token's owner should be equal to the caller of the function
        require(
            tokenOwner == _msgSender() ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ETH2NFTMarketPlace: Caller must be token owner or Admin role"
        );

        // get that token from all safe trees token mapping and create a memory of it defined as (struct => KDZTokenStruct)
        KDZTokenStruct memory updatedToken = _kdzTokens[_tokenId];

        // if token's forSale is false make it true and vice versa
        if (updatedToken.forSale) {
            updatedToken.forSale = false;
        } else {
            updatedToken.forSale = true;
        }

        // set and update that token in the mapping
        _setNewTokenState(_tokenId, updatedToken);
    }

    /**
     * @dev Get token's meta data
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getTokenMetaData(uint256 _tokenId)
        public
        virtual
        returns (
            bool forSale,
            uint256 tokenPrice,
            address tokenOwner
        )
    {
        // require caller of the function is not an empty address
        require(
            _msgSender() != address(0),
            "ETH2NFTMarketPlace: Caller of the function haven't been empty address"
        );

        // require that token should exist
        require(
            NFTContract.exists(_tokenId),
            "ETH2NFTMarketPlace: Get sale state of nonexistent token"
        );

        // get that token from all safe trees token mapping and create a memory of it defined as (struct => KDZTokenStruct)
        KDZTokenStruct memory matchedToken = _kdzTokens[_tokenId];

        // retreive token's meta data
        forSale = matchedToken.forSale;
        tokenPrice = matchedToken.price;
        tokenOwner = matchedToken.currentlyOwner;

        return (forSale, tokenPrice, tokenOwner);
    }

    /**
     * @dev Change the tokenId price
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice)
        public
        virtual
    {
        // require caller of the function is not an empty address
        require(
            _msgSender() != address(0),
            "ETH2NFTMarketPlace: Caller of the function haven't been empty address"
        );

        // require that token should exist
        require(
            NFTContract.exists(_tokenId),
            "ETH2NFTMarketPlace: Change price nonexistent token"
        );

        // get the token's owner
        address tokenOwner = NFTContract.ownerOf(_tokenId);

        // check that token's owner should be equal to the caller of the function
        require(
            tokenOwner == _msgSender() ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ETH2NFTMarketPlace: Caller must be token owner or admin"
        );

        // get that token from all safe trees token mapping and create a memory of it defined as (struct => KDZTokenStruct)
        KDZTokenStruct memory updatedToken = _kdzTokens[_tokenId];

        // update token's price with new price
        updatedToken.price = _newPrice;

        // set and update that token in the mapping
        _setNewTokenState(_tokenId, updatedToken);
    }
}
