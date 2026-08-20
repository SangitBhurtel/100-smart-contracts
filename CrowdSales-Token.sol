// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address account) external returns(uint256);
    function mint(address to, uint256 amount) external returns(bool);
    function burn(address from, uint256 amount) external returns(bool);
    function totalSupply() external returns(uint256);

}

contract CrowdSales {

    // Event
    event SaleListed(uint256 amount, uint256 saleEnd);
    event TokenBought(address by, uint256 amount);
    event SaleWithdrawn(uint256 id);

    // Errors
    error NotOwner();
    error NotEnoughTokenExists();
    error NotEnoughAmount();
    error OfferClosed();
    error InvalidAmount();
    error TransferFailed();
    error InvalidID();

    // State Variables
    IERC20 token;
    address owner;
    uint256 currentOfferId;

    struct Offers {
        uint256 amount;
        bool open;
        uint256 startTime;
        uint256 saleEnd;
        uint256 rate;
        uint256 offerId;
    }

    Offers[] public offer;


    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    modifier OwnerOnly {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function list(uint256 amount, uint256 endAfter, uint256 rate) external OwnerOnly {
        if (token.balanceOf(address(this)) < amount) revert NotEnoughTokenExists();

        Offers storage newOffer = offer.push();

        currentOfferId += 1;

        newOffer.amount = amount;
        newOffer.saleEnd = block.timestamp + endAfter;
        newOffer.open = true;
        newOffer.startTime = block.timestamp;
        newOffer.rate = rate;
        newOffer.offerId = currentOfferId;

        emit SaleListed(amount, block.timestamp + endAfter);
    }

    function buyToken(uint256 id) public payable {
        if (msg.value == 0) revert NotEnoughAmount();

        uint256 tokensOut = msg.value * offer[id].rate;

        if (!offer[id].open) revert OfferClosed();
        if (offer[id].saleEnd < block.timestamp) revert OfferClosed();
        if (offer[id].amount < tokensOut) revert InvalidAmount();


        offer[id].amount -= tokensOut;

        bool success = token.transfer(msg.sender, tokensOut);
        if (!success) revert TransferFailed();

        if (offer[id].amount == 0) offer[id].open = false;

        emit TokenBought(msg.sender, tokensOut);
    }

    function withdrawOffer(uint256 id) external OwnerOnly {
        offer[id].open = false;

        emit SaleWithdrawn(id);
    }

    function withdrawEth(uint256 amount, address to) external OwnerOnly {
        if (amount > address(this).balance) revert NotEnoughAmount();

        (bool success,) = to.call{value: amount} ("");
        if (!success) revert TransferFailed();
    }

    function withdrawFunds(uint256 amount, address to) external OwnerOnly {
        if (amount > token.balanceOf(address(this))) revert NotEnoughAmount();

        bool success = token.transfer(to, amount);
        if (!success) revert TransferFailed();
    }
}