// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Player is ERC721, Ownable {
    uint256 private tokenId;
    uint256 level;
    

    mapping (uint256 id => uint256 level) public levels;
    mapping (uint256 id => uint256 coins) public coinsBalance;

    constructor(address initialOwner)
        ERC721("MyToken", "MTK")
        Ownable(initialOwner)
    {}

    function mint(address _to) external onlyOwner returns (uint256 id) {
        id = tokenId++;
        _mint(_to, id);
    }

    function levelUp(uint256 _id,  uint256 coinsAmount) external onlyOwner {
        ++levels[_id];
        coinsBalance[_id] += coinsAmount;
    }

}