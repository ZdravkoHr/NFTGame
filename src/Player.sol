// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Player is ERC721, Ownable {
    uint256 level;

    mapping(uint256 id => uint256 level) public levels;
    mapping(uint256 id => uint256 time) public regeteredTime; // prevention for chest manipulation

    modifier onlyWorld() {
        if (msg.sender != world) {
            revert OnlyWorld();
        }
    }

    constructor(address _user, address _world) ERC721("Player", "PL") Ownable(_user) {
        world _world;
    }

    function levelUp(uint256 _id, uint256 coinsAmount) external onlyWorld {
        ++levels[_id];
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory)
        public
        virtual
        override
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        override
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
