// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {DutchAuction} from "../../src/DutchAuction.sol";
import {MyNFT} from "../../src/ERC721.sol";

contract Constructors is Test {
    DutchAuction private dutchAuction;
    MyNFT private nft;

    uint256 startingPrice = 1 ether;
    uint256 discountRate = 100 wei;
    uint256 nftId = 1;
    uint256 duration = 7 days;

    function setUp() public {
        nft = new MyNFT();
        nft.mint(address(this), nftId);
    }

    function test_nft_MintedCorrectly() public {
        assertEq(nft.ownerOf(nftId), address(this));
    }

    function test_dutchAuction_constructor() public {
        dutchAuction = new DutchAuction(
            startingPrice,
            discountRate,
            duration,
            address(nft),
            nftId
        );

        assertEq(dutchAuction.startingPrice(), startingPrice);
        assertEq(dutchAuction.discountRate(), discountRate);
        assertEq(address(dutchAuction.nft()), address(nft));
        assertEq(dutchAuction.nftId(), nftId);
        assertEq(dutchAuction.duration(), duration);
    }

    function test_RevertWhenDiscountGreaterThanStartingPrice() public {
        vm.expectRevert("starting price < discount");

        dutchAuction = new DutchAuction(
            startingPrice,
            discountRate + startingPrice,
            duration,
            address(nft),
            nftId
        );
    }
}

contract GetPrice is Test {
    DutchAuction private dutchAuction;
    MyNFT private nft;

    uint256 startingPrice = 1 ether;
    uint256 discountRate = 100 wei;
    uint256 nftId = 1;
    uint256 duration = 7 days;
    uint256 aliceEthBalance = 10 ether;

    function setUp() public {
        nft = new MyNFT();
        nft.mint(address(this), nftId);

        dutchAuction = new DutchAuction(
            startingPrice,
            discountRate,
            duration,
            address(nft),
            nftId
        );
    }

    function test_getPrice() public {
        uint256 price = dutchAuction.getPrice();
        assertEq(price, startingPrice);
    }

    function testFuzz_getPrice(uint256 time) public {
        vm.assume(time <= duration);
        skip(time);
        uint256 price = dutchAuction.getPrice();
        assertEq(price, startingPrice - (discountRate * time));
    }

    function invariant_getPrice() public {
        skip(duration);
        uint256 price = dutchAuction.getPrice();
        assertEq(price, startingPrice - (discountRate * duration));
    }
}

contract Buy is Test {
    address alice = vm.addr(1);

    DutchAuction private dutchAuction;
    MyNFT private nft;

    uint256 startingPrice = 1 ether;
    uint256 discountRate = 100 wei;
    uint256 nftId = 1;
    uint256 duration = 7 days;
    uint256 aliceEthBalance = 10 ether;

    function setUp() public {
        vm.label(address(alice), "Alice");
        vm.deal(alice, aliceEthBalance);

        nft = new MyNFT();
        nft.mint(address(this), nftId);

        dutchAuction = new DutchAuction(
            startingPrice,
            discountRate,
            duration,
            address(nft),
            nftId
        );
    }

    function test_buy() public {
        nft.approve(address(dutchAuction), nftId);
        uint256 price = dutchAuction.getPrice();
        assertEq(alice.balance, aliceEthBalance);

        vm.prank(alice);
        dutchAuction.buy{value: price * 3}();

        assertEq(alice.balance, aliceEthBalance - price);
        assertEq(nft.ownerOf(nftId), alice);
    }

    function test_RevertWhen_PriceGreaterThanSentETH() public {
        nft.approve(address(dutchAuction), nftId);
        uint256 price = dutchAuction.getPrice();
        assertEq(alice.balance, aliceEthBalance);

        vm.expectRevert("ETH < price");
        vm.prank(alice);
        dutchAuction.buy{value: price - 1}();
    }

    function test_RevertWhen_AuctionExpires() public {
        nft.approve(address(dutchAuction), nftId);
        uint256 price = dutchAuction.getPrice();
        assertEq(alice.balance, aliceEthBalance);
        skip(duration + 1);

        vm.expectRevert("auction expired");
        vm.prank(alice);
        dutchAuction.buy{value: price}();
    }
}
