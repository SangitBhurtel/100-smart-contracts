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

    // State variables
    bytes32 public ROOT_HASH;
    uint256 addresses;
    IERC20 public token;

    constructor(bytes32 _rootHash, address _token) {
        ROOT_HASH = _rootHash;
        token = IERC20(_token);    
    }

    function check(bytes32[] memory proof, uint256 amount, address receiver) internal returns(bool) {
        bytes32 checkFor =keccak256( abi.encodePacked(bytes32 (keccak256(abi.encodePacked(address(receiver), uint256(amount))))) );

        bytes32 currentHash = proof[0] < checkFor ? keccak256(abi.encodePacked(bytes32(proof[0]),bytes32(checkFor))) : keccak256(abi.encodePacked(bytes32(checkFor), bytes32(proof[0])));
        
        for (uint256 i = 1; i < proof.length + 1; i++) {

            currentHash = currentHash < proof[i] ? keccak256(abi.encodePacked(bytes32(currentHash), bytes32(proof[i]))) :  currentHash = keccak256(abi.encodePacked(bytes32(proof[i]), bytes32(currentHash)));
            
        }

        return currentHash == ROOT_HASH;
    }
}