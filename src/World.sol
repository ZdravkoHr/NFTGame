// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Player} from "./Player.sol";
import {Chest} from "./Chest.sol";
import {Coins} from "./Coins.sol";
import "./utils/Structs.sol";
import "./utils/Events.sol";
import "./utils/Errors.sol";

contract World is AccessControl,Events {
    bytes32 WORLD_ADMIN_ROLE = keccak256("WORLD_ADMIN");

    Player private playerContract;
    Coins private coinsContract;

    constructor(address _owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _setRoleAdmin(WORLD_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        playerContract = new Player();
        coinsContract = new Coins(address(this));
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


    function levelUp(uint256 id) external
        onlyRole(WORLD_ADMIN_ROLE)
        registeredPlayer(msg.sender, true)
    {
        uint8 decimals = coinsContract.decimals(); 
        uint256 mintAmount = 5 * 10 ** decimals;
        player.levelUp(id, mintAmount); 
        coinsContract.mint(address(playerContract), mintAmount);
    }

    function registerPlayer() external returns (uint256) {
        uint256 id = playerContract.mint(msg.sender);

        emit RegisterPlayer(msg.sender, id);
    }
}
