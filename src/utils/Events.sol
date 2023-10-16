// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

abstract contract Events {
    // World
    event PlayerTransferred(address indexed player, address fromWorld);
    event RegisterPlayer(address indexed owner, uint256 indexed id);
    event AddNewAdmin(address indexed admin);
    event RemoveAdmin(address indexed admin);

    // Potions
    event URIset(string indexed uri);
    event PotionMinted(address minter, uint256 indexed IDs, uint256 indexed amount);
    event BatchPotionMinted(address minter, uint256[] indexed IDs, uint256 indexed amount);

    // Coins
    event CoinsMinted(address indexed minter, uint256 amount);
}
