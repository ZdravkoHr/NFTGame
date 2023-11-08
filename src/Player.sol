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
    uint256 private level;
    uint private count;

    address private world;

    mapping(uint ID => uint level) private levels;

    mapping(uint256 id => uint256 time) public regeteredTime; // prevention for chest manipulation

    modifier onlyWorld() {
        if (msg.sender != world) {
            revert OnlyWorld();
        }
        _;
    }

    constructor(address _user, address _world) ERC721("Player", "PL") Ownable(_user) {
        world = _world;
    }

    function levelUp(uint ID) external onlyWorld {
        levels[ID]++;
    }
    function mint(address user) external onlyWorld returns(uint){
        count++;
        _mint(user,count);
        return count;
    }
}
