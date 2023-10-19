// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Player} from "./Player.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VRFConsumerBaseV2} from "@chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {EnumerableSet} from "@openzeppelincontracts/utils/structs/EnumerableSet.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Chest is VRFConsumerBaseV2, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    // ~~~VRF stats~~~
    VRFCoordinatorV2Interface public immutable VRF;
    uint64 private immutable subID;
    bytes32 private immutable gasLane;
    uint32 private immutable callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // ~~~Chest stats~~~
    enum PrizeType {
        Weapon,
        Potion,
        Coin
    }

    struct Prize {
        uint256 amount;
        uint256 ID;
    }

    EnumerableSet.UintSet private weaponChances;
    EnumerableSet.UintSet private potionChances;
    EnumerableSet.UintSet private coinChances;
    
    mapping(EnumerableSet.UintSet => mapping(uint256 ID => Prize)) public prizes;

    mapping(uint256 ID => mapping(uint256 time => bool claimed)) public claimed;

    uint256 public constant BIP = 100000; // 100k, 1 == 0.001
    uint256 public interval;
    uint256 public blockInterval; // used to prevent addressLottery manipulation
    uint256 public lastTimeCalled;
    uint256 public currentNumber;
    uint256 public currentID;

    Player public player;

    constructor(
        address _vrf,
        address _player,
        uint64 _subscriptionId,
        bytes32 _gasLane, // keyHash
        uint256 _interval, // 1 week
        uint256 _blockInterval, // 1 day
        uint32 _callbackGasLimit,
        address _world
    ) VRFConsumerBaseV2(_vrf) Ownable(_world) {
        VRF = VRFCoordinatorV2Interface(_vrf);
        player = Player(_player);
        gasLane = _gasLane;
        interval = _interval;
        subID = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        blockInterval = _blockInterval;

        if (!weaponChances.add(0)) revert ChanceNotAdded();
        if (!potionChances.add(0)) revert ChanceNotAdded();
        if (!coinChances.add(0)) revert ChanceNotAdded();
    }

    function addChance(PrizeType itemType, uint256 chance, uint256 amount, uint256 ID) external onlyOwner {
        if (chance > BIP) revert IncorrectChance();

        if (itemType == PrizeType.Weapon) {
            uint256 length = weaponChances.length();
            if (length > 0) {
                if (weaponChances.at(length - 1) >= chance) revert ChanceTooSmall();
            }
            prizes[itemType][length].amount = amount;
            prizes[itemType][length].ID = ID;
            if (!weaponChances.add(chance)) revert WeaponNotAdded(chance);
        } else if (itemType == PrizeType.Potion) {
            uint256 length = weaponChances.length();
            if (length > 0) {
                if (potionChances.at(length - 1) >= chance) revert ChanceTooSmall();
            }
            prizes[itemType][length].amount = amount;
            prizes[itemType][length].ID = ID;
            if (!potionChances.add(chance)) revert PotionNotAdded(chance);
        } else if (itemType == PrizeType.Coin) {
            uint256 length = weaponChances.length();
            if (length > 0) {
                if (coinChances.at(length - 1) >= chance) revert ChanceTooSmall();
            }
            prizes[itemType][length].amount = amount;
            prizes[itemType][length].ID = ID;
            if (!coinChances.add(chance)) revert CoinNotAdded(chance);
        } else {
            revert IncorrectItemType();
        }
    }

    function addChances(
        PrizeType[] calldata itemTypes,
        uint256[] calldata chances,
        uint256[] calldata amounts,
        uint256[] calldata IDs
    ) external onlyOwner {
        uint256 length = itemTypes.length;
        if (length != chances.length || length != amounts.length || length != IDs.length) {
            for (uint256 i; i < length; i++) {
                addChance(itemTypes[i], chances[i], amounts[i], IDs[i]);
            }
        }
    }

    function claimPrize(uint256 playerID) external {
        if (claimed[playerID][lastTimeCalled]) revert AlreadyClaimed();
        if (player.regeteredTime(playerID) - blockInterval > lastTimeCalled) revert TooLateToPlay();

        uint256 luckyNumber = uint256(bytes32(keccak256(abi.encodePacked(playerID, currentNumber))));
        uint256 itemType = luckyNumber % 3;
        uint256 itemChance = luckyNumber % BIP;

        if (itemType == uint256(PrizeType.Weapon)) {
            _itemRoll(weaponChances, itemChance);
        } else if (itemType == uint256(PrizeType.Potion)) {
            _itemRoll(potionChances, itemChance);
        } else {
            _itemRoll(coinChances, itemChance);
        }

        laimed[playerID][lastTimeCalled] = true;
    }

    function _itemRoll(EnumerableSet.UintSet set, uint256 chance) internal view returns (uint256) {
        uint256 length = set.length();
        for (uint256 i; i < length; i++) {
            if (set.at(i) <= chance) {
                if (set.at(set.length() - 1) == i) {
                    return i;
                } else if (set.at(i + 1) > chance) {
                    return i;
                }
                continue;
            }
        }
    }

    function roll() external {
        if (block.timestamp + interval <= lastTimeCalled) {
            revert TooEarly();
        }
        lastTimeCalled = block.timestamp;
        currentID = VRF.requestRandomWords(gasLane, subID, REQUEST_CONFIRMATIONS, callbackGasLimit, NUM_WORDS);
    }

    function adminRoll() external onlyOnwer {
        // if the first revert an admin can save this week's raffle
        lastTimeCalled = block.timestamp;
        currentID = VRF.requestRandomWords(gasLane, subID, REQUEST_CONFIRMATIONS, callbackGasLimit, NUM_WORDS);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        currentNumber = randomWords[0];
    }
}
