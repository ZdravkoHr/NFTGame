// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {Player} from './Structs.sol';
import '.utils/Events.sol';
import '.utils/Errors.sol';

contract World is AccessControl {
    bytes32 WORLD_ADMIN_ROLE = keccak256("WORLD_ADMIN");

    mapping (address player => mapping (address world => bool)) public playersWaitlist;
    mapping (address => Player) public playerInfo;
    mapping (address => bool) public supportedWorlds;

    constructor(address _owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _setRoleAdmin(WORLD_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    modifier registeredPlayer(address _owner, bool _required) {
        uint256 currentLevel = playerInfo[_owner];
        if (currentLevel == 0 && _required) {
            revert PlayerNotRegistered()
        }

        if (currentLevel != 0 && !_required) {
            revert PlayerAlreadyRegistered();
        }

        _;
    }

    function addAdmin(address _newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newAdmin == address(0)) revert InvalidAddress();
        _grantRole(WORLD_ADMIN_ROLE, _newAdmin);
        emit AddNewAdmin(_newAdmin);
    }

    function removeAdmin(address _admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_admin == address(0)) revert InvalidAddress();
        _revokeRole(WORLD_ADMIN_ROLE, _newAdmin);
        emit RemoveAdmin(_admin);
    }

    function updateSupportedWorlds(address _world, bool _isSupported) external onlyRole(WORLD_ADMIN_ROLE) {
        if (_world == address(0)) revert InvalidAddress();
        supportedWorlds[_world] = _isSupported;
    }

    function changeLevel(address _player, uint256 _newLevel) onlyRole(WORLD_ADMIN_ROLE) registeredPlayer(msg.sender, 1) {
        Player memory _playerInfo = playerInfo[player];
        _handleLevelChange(_playerInfo, _newLevel);
    }

    function approvePlayerTransfer(address _player, address _world) external onlyRole(WORLD_ADMIN_ROLE) {
        if (!playersWaitlist[_player][_world]) revert TransferNotRequested();
        Player memory _playerInfo = World(_world).transferPlayer(_player);

        // TODO: update _playerInfo

        playerInfo[_player] = _playerInfo;

        emit PlayerTransferred(_player, _world);

        delete playersWaitlist[_player][_world];
    }

    function registerPlayer() external registeredPlayer(msg.sender, 0) {
        Player memory _playerInfo = playerInfo[msg.sender];
    
        _playerInfo.level = 1;
        _playerInfo.owner = msg.sender;
        // TODO: mint default weapon

        playerInfo[msg.sender] = _playerInfo;
        emit RegisterPlayer(msg.sender);
    }

   
    function requestWorldChange(address _newWorld) external registeredPlayer(msg.sender, 1) {
        World(_newWorld).addPlayerToWaitlist(msg.sender);
    }

    function addPlayerToWaitlist(address _player) external {
        if (!supportedWorlds[msg.sender]) revert UnsupportedWorld();
        playersWaitlist[_player][msg.sender] = true;
    }

    function transferPlayer(address _player) external returns (Player memory) {
        if (!supportedWorlds[msg.sender]) revert UnsupportedWorld();
        Player memory _playerInfo = playerInfo[_player];

        // TODO: remove items, etc...

        delete playerInfo[_player];

        return _playerInfo;
    }

    function _handleLevelChange(Player memory _playerInfo, uint256 _newLevel) internal {
        _playerInfo.level = _newLevel;
        // TODO: change other stuff for the new level

        playerInfo[_playerInfo.owner] = _playerInfo; 
    }
}
