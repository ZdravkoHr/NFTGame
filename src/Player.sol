// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract Player is ERC721, Ownable, IERC1155Receiver {
    uint256 private tokenId;
    uint256 level;

    mapping(uint256 id => uint256 level) public levels;
    mapping(uint256 id => uint256 coins) public coinsBalance;

    constructor(address initialOwner) ERC721("MyToken", "MTK") Ownable(initialOwner) {}

    function mint(address _to) external onlyOwner returns (uint256 id) {
        id = tokenId++;
        _mint(_to, id);
    }

    function levelUp(uint256 _id, uint256 coinsAmount) external onlyOwner {
        ++levels[_id];
        coinsBalance[_id] += coinsAmount;
    }

    function setApprovalForERC20(IERC20 erc20, address to, uint256 amount) external onlyOwner {
        erc20.approve(to, amount);
    }

    function transferERC20(IERC20 erc20, address to, uint256 amount) external onlyOwner {
        erc20.transfer(to, amount);
    }

    function setApprovalForERC1155(IERC1155 erc1155, address to, bool approved) external onlyOwner {
        erc1155.setApprovalForAll(to, approved);
    }

    function transferERC1155(IERC1155 erc1155, address to, uint256 tokenID) external onlyOwner {
        erc1155.safeTransferFrom(address(this), to, tokenID, "");
    }

    function transferERC1155Batch(IERC1155 erc1155, address to, uint256[] calldata tokenIDs, uint256[] calldata amounts)
        external
        onlyOwner
    {
        erc1155.safeBatchTransferFrom(address(this), to, tokenIDs, amounts, "");
    }
}
