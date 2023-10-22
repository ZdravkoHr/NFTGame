// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

error PlayerAlreadyRegistered();
error TransferNotRequested();
error PlayerNotRegistered();
error UnsupportedWorld();
error InvalidAddress();
error NotAllowed();

//////////////////////////////////
//          ~~~Chest~~~         //
//////////////////////////////////

error TooEarly();
error InvalidType();
error TooLateToPlay();
error ChanceNotAdded();
error ChanceTooSmall();
error AlreadyClaimed();
error IncorrectChance();
error IncorrectItemType();

error WeaponNotAdded(uint256 chance);
error PotionNotAdded(uint256 chance);
error CoinNotAdded(uint256 chance);

error WeaponNotRemoved(uint256 chance);
error PotionNotRemoved(uint256 chance);
error CoinNotRemoved(uint256 chance);
