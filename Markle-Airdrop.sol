// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;


interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address account) external returns(uint256);
    function mint(address to, uint256 amount) external returns(bool);
    function burn(address from, uint256 amount) external returns(bool);
}

contract AirDrop {

    // Events
    event AirdropClaimed(address by, uint256 amount);

    // Errors
    error InvalidAmount();
    error ProofFailed();
    error AlreadyClaimed();
    error TransferFailed();

    // State variables
    bytes32 public ROOT_HASH;
    IERC20 public token;

    mapping (address => bool) claimed;

    constructor(bytes32 _rootHash, address _token) {
        ROOT_HASH = _rootHash;
        token = IERC20(_token);    
    }

    function check(bytes32[] memory proof, uint256 amount, address receiver) internal view returns(bool) {
        bytes32 checkFor = keccak256( abi.encodePacked(bytes32 (keccak256(abi.encode(address(receiver), uint256(amount))))) );
        bytes32 currentHash = proof[0] < checkFor ? keccak256(abi.encodePacked(bytes32(proof[0]),bytes32(checkFor))) : keccak256(abi.encodePacked(bytes32(checkFor), bytes32(proof[0])));
        
        for (uint256 i = 1; i < proof.length; i++) {
            currentHash = currentHash < proof[i] ? keccak256(abi.encodePacked(bytes32(currentHash), bytes32(proof[i]))) :  currentHash = keccak256(abi.encodePacked(bytes32(proof[i]), bytes32(currentHash)));
        }

        return currentHash == ROOT_HASH;
    }

    function claim(uint256 amount, bytes32[] calldata proof) external {

        if (claimed[msg.sender] == true) revert AlreadyClaimed();
        if (amount == 0) revert InvalidAmount();

        if (!check(proof, amount, msg.sender)) revert ProofFailed();

        claimed[msg.sender] = true;
        bool success = token.transfer(msg.sender, amount);

        if (!success) revert TransferFailed();

        emit AirdropClaimed(msg.sender, amount);
    }
}