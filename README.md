# Dutch Auction

This smart contract lets the deployer (seller) sell one NFT in a dutch auction style auction. The seller sets the NFT address and its id, with his desired starting price, discount rate and duration of the auction

After the buyer buys the NFT from the seller the contract is destroyed and all the ETH inside the contract is sent to the seller of the NFT

## What is a Dutch Auction

A Dutch auction (also called a descending price auction) refers to a type of auction in which an auctioneer starts with a very high price, incrementally lowering the price until someone places a bid. That first bid wins the auction (assuming the price is above the reserve price), avoiding any bidding wars. This contrasts with typical auction markets, where the price starts low and then rises as multiple bidders compete to be the successful buyer.
