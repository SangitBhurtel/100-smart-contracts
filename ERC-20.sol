// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

contract ERC20 {

    // Events
    event Minted(address to, uint256 amount);
    event Burned(address from, uint256  amount);
    event TransferFrom(address from, address to, uint256 amount);


    // Errors
    error NotEnoughToken();
    error NotEnoughAllowance(uint256 currentAllowance, uint256 amount);
    error OwnerOnly();


    // State variables
    uint256 public totalSupply;
    string public symbol;
    string public name;
    address public owner;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint256 amount, address mintTo) {
        totalSupply = amount;
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        balances[mintTo] += amount;
    }

    function mint(uint256 amount, address to) public {
        if (msg.sender != owner) revert OwnerOnly();
        balances[to] += amount;
        totalSupply += amount;
        emit Minted(to, amount);
    }

    function burn(uint256 amount) public {
        if (balances[msg.sender] < amount) revert NotEnoughToken();
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Burned(msg.sender, amount);
    }

    function approve(address from, uint256 amount) public {
        allowance[msg.sender][from] = amount;
    }

    function transfer(address to, uint256 amount) public {
        if (balances[msg.sender] < amount) revert NotEnoughToken();

        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit TransferFrom(msg.sender, to, amount);
    }

    function balanceOf(address from) public view returns(uint256) {
        return balances[from];
    }

    function transferFrom(address from, address to, uint256 amount) public {
        if (balances[from] < amount) revert NotEnoughToken();
        if (allowance[msg.sender][from] < amount) revert NotEnoughAllowance(allowance[msg.sender][from], amount);
        balances[to] += amount;
        balances[from] -= amount;
        allowance[msg.sender][from] -= amount;

        emit TransferFrom(from, to, amount);
    }
}