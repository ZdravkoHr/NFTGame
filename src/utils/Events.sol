// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

library Events {
    // World
    event PlayerTransferred(address indexed player, address fromWorld);
    event RegisterPlayer(address indexed owner);
    event AddNewAdmin(address indexed admin);
    event RemoveAdmin(address indexed admin);

    // Potions
    event URIset(string indexed uri);
    event PotionMinted(address minter, uint256 indexed IDs, uint256 indexed amount);
    event BatchPotionMinted(address minter, uint256[] indexed IDs, uint256 indexed amount);

    // Coins
    event CoinsMinted(address indexed minter, uint256 amount);

    // Chest
    event rollReqested(uint256 indexed id);
    event NewRandomNumber(uint256 indexed time, uint256 indexed number);
    event ItemAdded(PrizeType indexed itemType, uint256 indexed chance, uint256 indexed ID, uint256 amount);
}
