// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./utils/Events.sol";
import "./utils/Errors.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract Player is ERC721, Ownable {
    uint256 private count; // Counter 

    address private world; // Address of the creation world

    /*
      @notice maps playerIDs => their levels
      */
    mapping(uint256 playerID => uint256 level) private levels;

    /*
      @notice maps playerIDs => their registered time
      @dev used by chest to prevent player spam
      */
    mapping(uint256 playerID => uint256 time) public regesteredTime; 

    /*
      @notice used by world to level up players
      */
    modifier onlyWorld() {
        if (msg.sender != world) {
            revert OnlyWorld();
        }
        _;
    }

    constructor(address _user, address _world) ERC721("Player", "PL") Ownable(_user) {
        world = _world;
    }

    /*
      @notice increases the level of players
      @dev not used for now
      @param `ID` - playerID
      */
    function levelUp(uint256 playerID) external onlyWorld {
        levels[playerID]++;
    }
    /*
      @notice mints a new player
      @param `user` - the address of the minter
      */
    function mint(address user) external onlyWorld returns (uint256) {
        count++;
        regesteredTime[count] = block.timestamp;
        _mint(user, count);
        return count;
    }
}
