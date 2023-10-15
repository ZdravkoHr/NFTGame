// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {World} from './World.sol';

contract WorldFactory {
    function deployWorld() external returns (address world) {
         world = address(new World(msg.sender));
    }
}