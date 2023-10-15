// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

contract Events {
    event PlayerTransferred(address indexed player, address fromWorld);
    event RegisterPlayer(address indexed owner);
    event AddNewAdmin(address indexed admin);
    event RemoveAdmin(address indexed admin);
}
