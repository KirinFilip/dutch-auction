// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _nftId) external;
}

contract DutchAuction {
    event Sold(address indexed buyer, uint256 indexed price);

    IERC721 public immutable nft;
    uint256 public immutable nftId;

    address payable public immutable seller;
    uint256 public immutable startingPrice;
    uint256 public immutable startAt;
    uint256 public immutable expiresAt;
    uint256 public immutable discountRate;
    uint256 public immutable duration;

    constructor(
        uint256 _startingPrice,
        uint256 _discountRate,
        uint256 _duration,
        address _nft,
        uint256 _nftId
    ) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        startAt = block.timestamp;
        expiresAt = block.timestamp + _duration;
        discountRate = _discountRate;
        duration = _duration;

        // startingPrice must be greater than the discount
        require(
            _startingPrice >= _discountRate * _duration,
            "starting price < discount"
        );

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function getPrice() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - startAt;
        uint256 discount = discountRate * timeElapsed;
        return startingPrice - discount;
    }

    function buy() external payable {
        require(block.timestamp < expiresAt, "auction expired");

        uint256 price = getPrice();
        require(msg.value >= price, "ETH < price");

        // transfer the ownership of the nft
        nft.transferFrom(seller, msg.sender, nftId);

        // refund the excess ETH sent from the buyer
        uint256 refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        emit Sold(msg.sender, price);

        // close the auction by destroying the contract
        // and send ETH to the seller
        selfdestruct(seller);
    }
}
