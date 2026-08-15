// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

contract Voting {

    // Events
    event Ethreceived(uint256 amount);
    event EthSent(address to, uint256 amount);
    event Voted(address by);

    // Errors
    error NotOwner();
    error NotEnoughAmount();
    error RunningSubmission();
    error TransferFailed();
    error AlreadyVoted();


    // State variables
    address[] owners;
    uint256[] transactions;
    address[] votes;
    mapping(uint256 => bool) txSuccess; // Stores history of transactions
    mapping(uint256 txId => address[]) currentSubmissionVoting; // Current submission voting book
    mapping(uint256 txId => uint256 timeStarted) currentSubmissionTime;

    address ownerA;
    address ownerB;

    uint256 confirmationCount = 0;
    uint256 txID = 0;
    uint256 currentAmount = 0;
    address currentreceiver;

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

    function submit(address to, uint256 amount) public onlyOwner{
        if (amount > address(this).balance) revert NotEnoughAmount();

        if (currentSubmissionTime[txID] + TIME_TO_VOTE > block.timestamp) revert RunningSubmission();

        txID += 1;
        votes.push(msg.sender);
        currentAmount = amount;
        currentreceiver = to;

        currentSubmissionTime[txID] = block.timestamp;
        currentSubmissionVoting[txID] = votes;

        if (votes.length >= VOTES_NEEDED) {
            address payable receiver = payable(to);

            (bool success, ) = receiver.call{value: amount}("");

            if (!success) revert TransferFailed();

            txSuccess[txID] = true;

            emit EthSent(to, amount);
        }

        uint256 voterNumber = votes.length;
        for (uint256 i = 0; i < voterNumber; i++) {
            votes.pop();
        }

        emit Voted(msg.sender);
    }

    function vote() public onlyOwner{
        for (uint256 i = 0; i < votes.length; i++) {
            if (votes[i] == msg.sender) revert AlreadyVoted();
        }

        votes.push(msg.sender);

        if (votes.length >= VOTES_NEEDED) {
            address payable receiver = payable(currentreceiver);

            (bool success, ) = receiver.call{value: currentAmount}("");

            if (!success) revert TransferFailed();

            txSuccess[txID] = true;
            emit EthSent(currentreceiver, currentAmount);
        }

        uint256 voterNumber = votes.length;
        for (uint256 i = 0; i < voterNumber; i++) {
            votes.pop();
        }

        emit Voted(msg.sender);

    }

}