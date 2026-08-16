// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

contract TimeLock {

    // Events
    event FunctionCalled(uint256 CallID);
    event CallQueued(uint256 CallID, uint256 expiresIn);

    // Errors
    error NotOwner();
    error TimeLockNotLifted();
    error CallFailed();
    error AlreadyCalled();
    error CallCanceled();
    error NoSuchID();

    // State Variables
    uint256 constant public DELAY = 86400;
    address owner;

    uint256 queueID = 0;

    struct Calls {
        uint256 id;
        address to;
        uint256 startTime;
        uint256 amount;
        bytes data;
        bool executed;
        bool canceled;
    }

    Calls[] public calls;

    
    constructor() {
        owner = msg.sender;        
    }

    modifier OwnerOnly {
        if (msg.sender != owner) revert NotOwner();
        _;
    }


    function queue(address _to, uint256 _value, bytes memory _data) external OwnerOnly {
       Calls storage newCall = calls.push();


       newCall.startTime = block.timestamp;
       newCall.to = _to;
       newCall.id = queueID;
       newCall.amount = _value;
       newCall.data = _data;
       newCall.executed = false;
       newCall.canceled = false;

        queueID += 1;
    }

    function cancelCall(uint256 _id) external OwnerOnly{
        calls[_id].canceled = true;
    }

    function call(uint256 _id)  external {
        if (calls.length <= _id) revert NoSuchID();
        if (calls[_id].startTime + DELAY > block.timestamp) revert TimeLockNotLifted();
        if (calls[_id].executed) revert AlreadyCalled();
        if (calls[_id].canceled) revert CallCanceled();

        (bool success,) = calls[_id].to.call{value: calls[_id].amount}(calls[_id].data);

        if (!success) revert CallFailed();

        calls[_id].executed = true;

        emit FunctionCalled(_id);
    }
}