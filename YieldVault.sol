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

contract YeildVault {

    // Errors
    error InvalidAmount();
    error TransferFailed();
    error NotEnoughShares();
    error BurnFailed();

    // Events
    event FundsDeposited(address by, uint256 amount);
    event FundsWithdrawn(address by, uint256 amount);
    
    // State Variable
    IERC20 shares;
    IERC20 asset;


    
    constructor(address _shares, address _asset) {
        shares = IERC20(_shares);
        asset = IERC20(_asset);

        shares.mint(address(this), 1);
        asset.mint(address(this), 1);
    }

    function calculateShares(uint256 _amount, uint256 assetBalance) private returns(uint256) {
        if (_amount == 0) revert InvalidAmount();

        return (_amount * shares.totalSupply()) / assetBalance;
    }

    function deposit(uint256 amount) external payable {
        if (amount == 0) revert InvalidAmount();

        uint256 assetBefore = asset.balanceOf(address(this));
        bool check = asset.transferFrom(msg.sender, address(this), amount);
        if (!check) revert TransferFailed();

        bool success = shares.mint(msg.sender, calculateShares(amount, assetBefore));
        if (!success) revert TransferFailed();

        emit FundsDeposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        if (amount > shares.balanceOf(msg.sender)) revert NotEnoughShares();

        uint256 assetsOwed = (amount * asset.balanceOf(address(this))) / shares.totalSupply();

        bool success = shares.burn(msg.sender, amount);
        if (!success) revert BurnFailed();

        bool sent = asset.transfer(msg.sender, assetsOwed);
        if (!sent) revert TransferFailed();

        emit FundsWithdrawn(msg.sender, amount);
    }
}