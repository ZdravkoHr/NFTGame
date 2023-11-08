// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Item} from "./Item.sol";
import {Player} from "./Player.sol";
import {Chest} from "./Chest.sol";
import {Coins} from "./Coins.sol";
import "./utils/Events.sol";
import "./utils/Errors.sol";

contract World is AccessControl {
    bytes32 WORLD_ADMIN_ROLE = keccak256("WORLD_ADMIN");

    Player private playerContract;
    Chest private chestContract;
    Coins public coinsContract;
    Item public itemContract;

    mapping(uint256 playerID => address owner) private playerOwners;

    uint256 levelMintAmount;

    constructor(address _owner, uint256 _levelMintAmount) {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _setRoleAdmin(WORLD_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        // chestContract = new Chest()
        coinsContract = new Coins(address(this),address(this));
        itemContract = new Item(address(this),address(this));
        levelMintAmount = _levelMintAmount;
    }

    function addAdmin(address _newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newAdmin == address(0)) revert InvalidAddress();
        _grantRole(WORLD_ADMIN_ROLE, _newAdmin);
        emit Events.AddNewAdmin(_newAdmin);
    }

    function removeAdmin(address _admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_admin == address(0)) revert InvalidAddress();
        _revokeRole(WORLD_ADMIN_ROLE, _admin);
        emit Events.RemoveAdmin(_admin);
    }

    function levelUp(uint256 ID) external onlyRole(WORLD_ADMIN_ROLE) {
        if (playerOwners[ID] == address(0)) revert InvalidAddress();
        uint8 decimals = coinsContract.decimals();
        uint256 mintAmount = levelMintAmount * 10 ** decimals;
        playerContract.levelUp(ID);
        coinsContract.mint(playerOwners[ID], mintAmount);
    }

    function registerPlayer() external {
        uint256 ID = playerContract.mint(msg.sender);
        playerOwners[ID] = msg.sender;
        emit Events.RegisterPlayer(msg.sender);
    }

    function changeLevelMint(uint256 _levelMintAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        levelMintAmount = _levelMintAmount;
    }
}
