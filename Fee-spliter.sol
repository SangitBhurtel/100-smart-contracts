// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address account) external returns(uint256);
    function mint(address to, uint256 amount) external returns(bool);
    function burn(address from, uint256 amount) external returns(bool);
}

contract FeeSplit { 
    // State Variable
    IERC20 public token;
    mapping(address => uint256) userShare;
    address addressA;
    address addressB;
    address addressC;
    address[] users = [addressA, addressB, addressC];

    // Event
    event FundsRecieved(uint256 amount);
    event FundsTransfered(address to, uint256 amount);

    //Errors
    error TransactionFailed(address to);

    constructor (address _token, address _addressA, address _addressB, address _addressC) {
        token = IERC20(_token);
        addressA = _addressA;
        addressB = _addressB;
        addressC = _addressC;

        userShare[addressA] = 50;
        userShare[addressB] = 30;
        userShare[addressC] = 20;
    }

    function split() public{
        for (uint256 i = 0; i < users.length; i++) {
            uint256 amount = (address(this).balance * userShare[users[i]]) / 100 ;
            bool transfer = token.transfer(users[i], amount);
            if (!transfer) revert TransactionFailed(users[i]);
            emit FundsTransfered(users[i], amount);
        }
    }

    function recieve() payable public {
        emit FundsRecieved(msg.value);
    }
}