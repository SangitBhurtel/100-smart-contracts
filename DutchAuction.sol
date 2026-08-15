// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

contract DutchAuction {

    // Event
    event Sold(address buyer, uint256 amount);
    event Withdrawn();

    // Errors
    error NotOwner();
    error TransactionFailed(uint256 suppliedPrice, uint256 actualPrice);
    error AuctionClosed();
    error TransferFailed();
    error RefundFailed();
    error AuctionNotEnded();

    // State Variables
    
    uint256 public startingPrice;
    uint256 public floorPrice;
    address public owner;
    uint256 public startingTime;
    bool public auctionOpen;
    uint256 public duration;


    constructor (uint256 _startingPrice, uint256 _floorPrice, uint256 _duration){
        startingPrice = _startingPrice;
        floorPrice = _floorPrice;
        owner = msg.sender;
        startingTime = block.timestamp;
        auctionOpen = true;
        duration = _duration;
    }

    function getPrice() public view returns(uint256) {
        uint256 priceDiff = startingPrice - floorPrice;
        uint256 timeDiff = block.timestamp - startingTime;
        uint256 currentPrice = startingPrice - (priceDiff * timeDiff / duration);
        if (currentPrice < floorPrice) return floorPrice;
        return currentPrice;
    }

    function buy() public payable {
        if(!auctionOpen) revert AuctionClosed();

        uint256 price = getPrice();

        
        if (msg.value < price) revert TransactionFailed(msg.value, price);

        if (msg.value > getPrice()) { 
            (bool refundSuccess,) = msg.sender.call{value: msg.value - price}("");
            if(!refundSuccess) revert RefundFailed();
        }

        auctionOpen = false;

        (bool success,) = owner.call{value: address(this).balance} ("");
        if (!success) revert TransferFailed();
        emit Sold(msg.sender, msg.value);
    }

    function reclaim() public {
        if (msg.sender != owner) revert NotOwner();
        if (block.timestamp < startingTime + duration) revert AuctionNotEnded();
        auctionOpen = false;

        (bool success,) = owner.call{value: address(this).balance} ("");
        if (!success) revert TransferFailed();

        emit Withdrawn();
    }
} 