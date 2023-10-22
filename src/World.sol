// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Potions} from "./Potions.sol";
import {Player} from "./Player.sol";
import {Chest} from "./Chest.sol";
import {Coins} from "./Coins.sol";
import "./utils/Structs.sol";
import "./utils/Events.sol";
import "./utils/Errors.sol";

contract World is AccessControl, Events {
    bytes32 WORLD_ADMIN_ROLE = keccak256("WORLD_ADMIN");

    Player private playerContract;
    Chest private chestContract;
    Coins public coinsContract;
    Potion public potionsContract;

    mapping(address user => uint256 playerCount) private playerCount;
    mapping(address player => address owner) private playerOwners;

    uint256 levelMintAmount;

    constructor(address _owner, uint256 _levelMintAmount) {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _setRoleAdmin(WORLD_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        // chestContract = new Chest()
        coinsContract = new Coins(address(this),address(this));
        potionsContract = new Potion(address(this),address(this));
        levelMintAmount = _levelMintAmount;
    }

    function addAdmin(address _newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newAdmin == address(0)) revert InvalidAddress();
        _grantRole(WORLD_ADMIN_ROLE, _newAdmin);
        emit AddNewAdmin(_newAdmin);
    }

    function removeAdmin(address _admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_admin == address(0)) revert InvalidAddress();
        _revokeRole(WORLD_ADMIN_ROLE, _admin);
        emit RemoveAdmin(_admin);
    }

    function levelUp(address player) external onlyRole(WORLD_ADMIN_ROLE) {
        if (playerOwners[player] == address(0)) revert InvalidAddress();
        uint8 decimals = coinsContract.decimals();
        uint256 mintAmount = levelMintAmount * 10 ** decimals;
        player.levelUp(id);
        coinsContract.mint(address(player), mintAmount);
    }

    function registerPlayer() external {
        address player = new Player(msg.sender,address(this));
        playerOwners[player] = msg.sender;
        playerCount[msg.sender]++;

        emit RegisterPlayer(msg.sender);
    }

    function changeLevelMint(uint256 _levelMintAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        levelMintAmount = _levelMintAmount;
    }
}
