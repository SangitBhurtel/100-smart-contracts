// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address account) external returns(uint256);
    function mint(address to, uint256 amount) external returns(bool);
    function burn(address from, uint256 amount) external returns(bool);
}

contract Collateral {
    // Errors
    error NotEnoughToken();
    error NotEnoughCollateralAvailable();

    // Events
    event TokenDeposited(address by, uint256 amount);
    event TokenWithdrawn(address by, uint256 amount);

    // State Variables
    mapping(address => uint256) userDeposits;
    IERC20 public token;
    IERC20 public stableToken;
    uint256 constant public RATIO = 150;


    constructor() {
        token = IERC20(token);
        stableToken = IERC20(stableToken);
    }

    function deposit(uint256 amount) public payable {
        if (amount == 0) revert NotEnoughToken();

        token.transferFrom(msg.sender,address(this), amount);
        userDeposits[msg.sender] += amount;
        emit TokenDeposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        if (amount == 0) revert NotEnoughToken();

        userDeposits[msg.sender] -= amount;
        token.transfer(msg.sender,amount);

        emit TokenWithdrawn(msg.sender,amount);
    }

    function mint(uint256 amount) public {
        if (amount == 0) revert NotEnoughToken();

        if (userDeposits[msg.sender] == 0 && userDeposits[msg.sender] > amount * RATIO / 100) revert NotEnoughCollateralAvailable();

        stableToken.mint(msg.sender, amount);
    }

    function burn(uint256 amount) public {
        
    }
}