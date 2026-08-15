// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

import "./ERE-20.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address account) external returns(uint256);
    function mint(address to, uint256 amount) external returns(bool);
    function burn(address from, uint256 amount) external returns(bool);
}

contract AAM {
    // Errors
    error NotEnoughToken();
    error UserNotFound();

    // Event
    event LiquidityAdded(address by, uint256 amount);


    // State Variables
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalPool;
    ERC20 public lpToken;


    mapping(address => uint256) userShare;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        lpToken = new ERC20("LP Token", "LP", 0, address(this));
    }

    function addLiquid(uint256 amount) public {
        if (amount == 0) revert NotEnoughToken();

        tokenA.transferFrom(msg.sender, address(this), amount);
        tokenB.transferFrom(msg.sender, address(this), amount);
        userShare[msg.sender] += amount;
        lpToken.mint(amount, msg.sender);
        emit LiquidityAdded(msg.sender, amount);
    }

    function rewardCalc(address user) public returns(uint256){
        if (userShare[user] == 0) revert UserNotFound();

        
    }


}