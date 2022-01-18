// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// ----------------------------------------------------------------------------
// NFT2ETHMarketPlace - KDZ NFT MarketPlace, Exchange with ETH
//
// Copyright (c) 2022 Kenny Dizi
//
// ----------------------------------------------------------------------------

import "./KDZTokenConfig.sol";
import "./BaseMarketPlace.sol";

contract NFT2ETHMarketPlace is BaseMarketPlace, KDZTokenConfig {
    // name of market place
    string private _name;

    /**
     * @dev Sets the values for {name}, {nftContractAddress}
     */
    constructor(address nftContractAddress)
        BaseMarketPlace(nftContractAddress)
    {
        _name = KDZ_MARKETPLACE_NAME;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Buy a NFT with ETH by passing tokenId
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function buyToken(uint256 _tokenId) public payable {
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
            tokenOwner != _msgSender(),
            "ETH2NFTMarketPlace: Caller must be difference with message sender"
        );

        // get that token from all safe trees token mapping and create a memory of it defined as (struct => SAFETREESToken)
        KDZTokenStruct memory matchedToken = _kdzTokens[_tokenId];

        // token should be for sale
        require(
            matchedToken.forSale,
            "ETH2NFTMarketPlace: Token have to sellable state."
        );

        // price sent in to buy should be equal to or more than the token's price
        require(
            msg.value >= matchedToken.price,
            "ETH2NFTMarketPlace: The value have to larger or equal token price"
        );

        // get owner of the token
        address payable sendTo = matchedToken.currentlyOwner;

        // send token's worth of ethers to the owner
        sendTo.transfer(msg.value);

        // transfer the token from owner to the caller of the function (buyer)
        NFTContract.safeTransferFrom(tokenOwner, _msgSender(), _tokenId);

        // update the token's current owner
        matchedToken.currentlyOwner = payable(_msgSender());

        // set and update that token in the mapping
        _setNewTokenState(_tokenId, matchedToken);
    }
}
