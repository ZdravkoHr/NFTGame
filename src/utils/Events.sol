// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

contract Events {

    // World
    event PlayerTransferred(address indexed player, address fromWorld);
    event RegisterPlayer(address indexed owner, uint256 indexed id);
    event AddNewAdmin(address indexed admin);
    event RemoveAdmin(address indexed admin);

    // Potions
    event URIset(string memory indexed uri);
    event PotionMinted(address minter,uint indexed ID, uint indexed amount);
    event BatchPotionMinted(address minter,uint[] ID, uint indexed amount);

    // Coins
    event CoinsMinted(address indexed minter,uint amount);
}
