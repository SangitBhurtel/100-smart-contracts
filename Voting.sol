// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

contract Voting {

    // Events
    event Ethreceived(uint256 amount);
    event EthSent();
    event Voted(address by);

    // Errors
    error NotOwner();
    error NotEnoughAmount();
    error RunningSubmission();
    error TransferFailed();
    error AlreadyVoted();
    error InvalidAmount();
    error SubmissionExpired();
    error SubmissionExecuted();


    // State variables
    address[] owners;
    struct Transactions {
        uint256 Id;
        bool txSuccess;
        address[] voted;
        uint256 timeStarted;
        uint256 expiry;
        uint256 amount;
        address to;
    }

    Transactions[] public transactions;


    address ownerA;
    address ownerB;


    uint256 constant public TIME_TO_VOTE =  60;
    uint256 constant public VOTES_NEEDED = 2;

    modifier onlyOwner {
        bool _owner = false;

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                _owner = true;
                break; 
            }
        }
        if (!_owner) revert NotOwner();
        _;
    }


    constructor(address _ownerA, address _ownerB) {
        owners.push(_ownerA);
        owners.push(_ownerB);
        owners.push(msg.sender);
    }

    receive() external payable  {
        emit Ethreceived(msg.value);
    }

    function submit(address _to, uint256 _amount) public onlyOwner{
        if (_amount > address(this).balance) revert NotEnoughAmount();
        if (_amount == 0) revert InvalidAmount();
            
        if (transactions.length != 0 && transactions[transactions.length - 1].expiry > block.timestamp) revert RunningSubmission();

        Transactions storage newTransaction = transactions.push();


        newTransaction.txSuccess = false;
        newTransaction.voted.push(msg.sender);
        newTransaction.timeStarted = block.timestamp;
        newTransaction.expiry = block.timestamp + TIME_TO_VOTE;
        newTransaction.amount = _amount;
        newTransaction.to = _to;
    }

    function vote(uint256 _txID) public onlyOwner{
        if (transactions.length != 0 && transactions[_txID].expiry > block.timestamp) revert SubmissionExpired();
        if (transactions.length != 0 && transactions[_txID].txSuccess) revert SubmissionExecuted();

        for (uint256 i = 0; i < transactions[_txID].voted.length; i++) {
            if (transactions[_txID].voted[i] == msg.sender) revert AlreadyVoted();
        }
        transactions[_txID].voted.push(msg.sender);

        if (transactions[_txID].voted.length >= VOTES_NEEDED ) {

            transactions[_txID].txSuccess = true;
            (bool success,) = transactions[_txID].to.call{value: transactions[_txID].amount}("");

            if (!success) revert TransferFailed();
            emit EthSent();
        }
    }
}