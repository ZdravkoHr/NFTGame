// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./utils/Events.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Coins is ERC20, ERC20Burnable, AccessControl, Events {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address owner,address chest) ERC20("Coins", "CN") {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(MINTER_ROLE, chest);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
        emit CoinsMinted(to, amount);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20) {
        super._update(from, to, value);
    }
}
