// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address account) external returns(uint256);
    function mint(address to, uint256 amount) external returns(bool);
    function burn(address from, uint256 amount) external returns(bool);
}

contract Staking {

    // Events
    event StakingAmountAdded(address by, uint256 amount);
    event StakingAmountRemoved(address by, uint256 amount);
    event Rewarded(address addrs, uint256 amount);
    event RewardPoolSeeded(uint256 amount);

    //Errors
    error NotOwner();
    error NotEnoughAmount();
    error TransferFailed();
    error MoreThanStaked();
    error NotValidAddress();
    error NoUserFound();
    error InvalidAmount();

    // State variable
    IERC20 public stakingToken;
    address public owner;
    mapping (address => uint256) stakedAmount;
    mapping (address => uint256) lastClaimed;
    uint256 constant public REWARD_RATE = 1e14;
    IERC20 public rewardToken;

    constructor(address _tokenS, address _tokenR) {
        stakingToken = IERC20(_tokenS);
        rewardToken = IERC20(_tokenR);
        owner = msg.sender;        
    }

    modifier OwnerOnly {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function stake(uint256 amount) public {
        if (amount == 0) revert NotEnoughAmount();

        uint256 rewards = pendingRewards(msg.sender);
        if (rewards > 0) claimReward(rewards);

        bool transferSuccess = stakingToken.transferFrom(msg.sender, address(this), amount);
        if (!transferSuccess) revert TransferFailed();

        stakedAmount[msg.sender] += amount;
        lastClaimed[msg.sender] = block.timestamp;

        emit StakingAmountAdded(msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        if (amount == 0) revert NotEnoughAmount();
        if (amount > stakedAmount[msg.sender]) revert MoreThanStaked();

        uint256 rewards = pendingRewards(msg.sender);
        if (rewards > 0) claimReward(rewards);
        stakedAmount[msg.sender] -= amount;
        bool transferSuccess = stakingToken.transfer(msg.sender, amount);

        if(!transferSuccess) revert TransferFailed();

        emit StakingAmountRemoved(msg.sender, amount);
    }

    function pendingRewards(address user) public view returns(uint256) {
        if (user == address(0)) revert NotValidAddress();

        uint256 claimableTime = block.timestamp - lastClaimed[user];

        return stakedAmount[user] * REWARD_RATE * claimableTime / 1e18;
    }

    function claimReward(uint256 amount) public {
        if (amount == 0) revert NotEnoughAmount();

        uint256 claimableReward = pendingRewards(msg.sender);
        if (amount > claimableReward) revert  InvalidAmount();

        lastClaimed[msg.sender] = block.timestamp;
        rewardToken.transfer(msg.sender, amount);

        emit Rewarded(msg.sender, amount);
    }

    function fund(uint256 amount) OwnerOnly public {
        rewardToken.transferFrom(msg.sender, address(this), amount);

        emit RewardPoolSeeded(amount);
    }
}