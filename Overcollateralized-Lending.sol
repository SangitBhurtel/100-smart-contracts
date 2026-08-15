// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address account) external returns(uint256);
    function mint(address to, uint256 amount) external returns(bool);
    function burn(address from, uint256 amount) external returns(bool);
}

contract OvercollateralizedLending {

    // State Variables
    IERC20 public token;
    mapping(address => uint256) userDeposits;
    mapping(address => uint256) userBorrows;
    uint256 constant public BORROW_RATIO = 150;
    address public owner;

    // Events
    event EthDeposited(address by, uint256 amount);
    event TokenBorrowed(address by, uint256 amount);
    event Repaid(address by, uint256 amount);
    event EthWithdrawn(address by, uint256 amount);
    event PoolFunded(uint256 amount);

    // Errors
    error NotEnoughEth();
    error NotEnoughAmount();
    error NoCollateralDeposited();
    error CannotBorrowCollateralMaxed();
    error CannotWithdrawCollateralMaxed();
    error TransferFailed();
    error NotOwner();

    
    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    modifier OwnerOnly {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function deposit() payable public {
        if (msg.value == 0) revert NotEnoughEth();
        
        userDeposits[msg.sender] += msg.value;

        emit EthDeposited(msg.sender, msg.value);
    }

    function borrow(uint256 amount) public {
        if (amount == 0) revert NotEnoughAmount();
        if (userDeposits[msg.sender] == 0) revert NoCollateralDeposited();
        

        uint256 adjustedBorrows = (userBorrows[msg.sender] * 150) / 100;
        uint256 borrowable = userDeposits[msg.sender] - adjustedBorrows;

        if (amount > borrowable) revert CannotBorrowCollateralMaxed();

        userBorrows[msg.sender] += amount;

        token.transfer(msg.sender, amount);

        emit TokenBorrowed(msg.sender, amount);
    }

    function repay(uint256 amount) public {
        if (amount == 0) revert NotEnoughAmount();

        token.transferFrom(msg.sender, address(this), amount);
        userBorrows[msg.sender] -= amount;
        
        emit Repaid(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        if (amount == 0) revert NotEnoughAmount();

        if (userDeposits[msg.sender] == 0) revert NoCollateralDeposited();

        uint256 adjustedBorrows = (userBorrows[msg.sender] * 150) / 100;
        uint256 borrowable = userDeposits[msg.sender] - adjustedBorrows;

        if (amount > borrowable) revert CannotWithdrawCollateralMaxed();

        userDeposits[msg.sender] -= amount;
        (bool success,) = msg.sender.call{value: amount}("");

        if(!success) revert TransferFailed();

        emit EthWithdrawn(msg.sender, amount);
    }

    function fund(uint256 amount) OwnerOnly public {
        token.mint(address(this),amount);
        emit PoolFunded(amount);
    }
}