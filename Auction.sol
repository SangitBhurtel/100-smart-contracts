// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

contract Auction {

    // Events
    event AuctionListed(uint256 startsAt, uint256 baseAmount);

    // Errors
    error NotEnoughAmount();
    error NotStartedYet();
    error AuctionClosed();
    error TransferFailed();
    error NotOwner();

    // State Variables
    uint256 startTime;
    uint256 timeLimit = 10;
    uint256 startPrice;
    uint256 public constant MINIMUM_ENCREMENT = 1;
    address owner;
    uint256 public currentPrice;
    uint256 public lastBetTime;
    bool open;
    address currentBidder;
    bool first = true;


    constructor(uint256 _startTime, uint256 _startPrice ) {
        startTime = _startTime;
        startPrice = _startPrice;      
        owner = msg.sender;
        currentPrice = startPrice;
        lastBetTime = startPrice;

        emit AuctionListed(startTime, startPrice);
    }

    function buy() public payable {
        if (block.timestamp < startTime) revert NotStartedYet();
        if ((lastBetTime + timeLimit) < block.timestamp) open =false;
        if (!open) revert AuctionClosed();            

        if (msg.value == 0) revert NotEnoughAmount();
        if (msg.value < currentPrice) revert NotEnoughAmount();
        if (msg.value < MINIMUM_ENCREMENT) revert NotEnoughAmount();

        if (!first) {
            (bool success,) = currentBidder.call{value: currentPrice}("");
            if (!success) revert TransferFailed();
        } 

        first = false;
        currentPrice = msg.value;
        currentBidder = msg.sender;
        lastBetTime = block.timestamp;
    }

    function withdrawEth(uint256 amount, address to) external {
        if (msg.sender != owner) revert NotOwner();
        if (amount > address(this).balance) revert NotEnoughAmount();

        (bool success,) = to.call{value: amount} ("");
        if (!success) revert TransferFailed();
    }
}