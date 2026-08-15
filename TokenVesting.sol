// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

import "./ERE-20.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVesting {
    

    // Errors
    error NotBeneficiary();
    error AlreadyClaimed();
    error CliffNotEnded();
    error NoBalanceRemaining();
    error NotClaimable(uint256 claimable);
    error TransferFailed();
    error NotOwner();

    uint256 public contractStart;
    uint256 public contractEnd;
    uint256 public cliffEnd;
    uint256 public vestingStart;
    uint256 public totalAmount;
    address public tokenAddress;
    address public beneficiary;
    address public owner;
    IERC20 public token;
    
    uint256 claimedAmount = 0;
    uint256 public claimableAmount;

    bool public revoked = false;


    constructor( uint256 _contractStart, uint256 _contractEnd, uint256 _cliffEnd, uint256 _vestingStart, uint256 _amount, address _tokenAddress, address _beneficiary) {
        beneficiary = _beneficiary;
        contractStart = _contractStart;
        contractEnd = _contractEnd;
        cliffEnd = _cliffEnd;
        vestingStart = _vestingStart;
        totalAmount = _amount;
        token = IERC20(_tokenAddress);
        owner = msg.sender;
    }

    function claim() public {
        if (msg.sender != beneficiary) revert NotBeneficiary();
        if (totalAmount == claimedAmount) revert NoBalanceRemaining();
        if (block.timestamp < cliffEnd) revert CliffNotEnded();

        uint256 elapsed = block.timestamp - contractStart;
        uint256 duration = contractEnd - contractStart;

        uint256 vestedAmount = totalAmount * elapsed / duration;
        claimableAmount = vestedAmount - claimedAmount;
        claimedAmount += claimableAmount;
        bool success = token.transfer(beneficiary, claimableAmount);

        if (!success) revert TransferFailed();
    }

    function revoke() public {
        if (msg.sender != owner) revert NotOwner();

        revoked = true;
        claimableAmount = claimable();

        token.transfer(beneficiary, claimableAmount);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function claimable() public view returns(uint256) {
        uint256 elapsed = block.timestamp - contractStart;
        uint256 duration = contractEnd - contractStart;

        uint256 vestedAmount = totalAmount * elapsed / duration;
        return vestedAmount - claimedAmount;
    } 


}