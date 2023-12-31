// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./utils/Events.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Coins is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    constructor(address world, address chest) ERC20("Coins", "CN") {
        _grantRole(DEFAULT_ADMIN_ROLE, world);
        _grantRole(MINTER_ROLE, world);
        _grantRole(MINTER_ROLE, chest);
    }

    /*
      @notice mints coins to users
      @dev `MINTER_ROLE` should be world and chest
      @param `to` - receiver address
      @param `amount` - amount of tokens that should be received
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
        emit Events.CoinsMinted(to, amount);
    }
}
