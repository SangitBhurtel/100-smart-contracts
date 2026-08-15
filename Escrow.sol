// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

contract Escrow {

    // Events
    event Refunded(address to, uint256 amount);
    event Approved(address to, uint256 amount);

    // Errors
    error NotArbiter();
    error TransferFailed();
    error NotEnoughBalance();

    address public arbiter;
    address public beneficary;
    address public depositer;
    uint256 public balance;

    constructor(address _arbiter, address _beneficiary) payable {
        arbiter = _arbiter;
        beneficary = _beneficiary;
        balance = msg.value;
        depositer = msg.sender;
    }
    
    function refund() public {
        if (msg.sender != arbiter) revert NotArbiter();
        if(balance == 0) revert NotEnoughBalance();

        uint256 send = balance;
        balance = 0;

        (bool success,) = depositer.call{value: send}("");
        if (!success) revert TransferFailed();

        emit Refunded(depositer, send);
    }

    function approve() public {
        if (msg.sender != arbiter) revert NotArbiter();
        if(balance == 0) revert NotEnoughBalance();

        uint256 send = balance;
        balance = 0;

        (bool success,) = beneficary.call{value: send}("");
        if (!success) revert TransferFailed();

        emit Approved(beneficary, send);
    }

    function getBalance() public view returns(uint256) {
        return balance;
    }
}