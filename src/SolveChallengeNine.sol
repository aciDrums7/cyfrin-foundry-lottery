// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// ERC721

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface Challenge {
    function solveChallenge(
        uint256 randomGuess,
        string memory yourTwitterHandle
    ) external;
}

contract SolveChallengeNine is IERC721Receiver {
    address constant CHALLENGE_ADDRESS =
        0x33e1fD270599188BB1489a169dF1f0be08b83509;
    address i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    //////////////////////
    // Public Functions //
    //////////////////////

    function solve() public /* returns (bytes4, bool) */
    {
        uint256 guess = getTheGess();

        // (bool success, bytes memory returnData) = CHALLENGE_ADDRESS.call(abi.encodeWithSelector(getSelector(), guess, "yourTwitterHandle"));
        // return (bytes4(returnData), success);

        Challenge challenge = Challenge(CHALLENGE_ADDRESS);
        challenge.solveChallenge(guess, "acidrums7");
    }

    // ERC721 Token Receiver Interface implementation
    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        forwardNFT(msg.sender, tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    //////////////////////
    // Private Functions //
    //////////////////////

    function getTheGess() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        block.prevrandao,
                        block.timestamp
                    )
                )
            ) % 100000;
    }

    function getSelector() private pure returns (bytes4 selector) {
        selector = bytes4(keccak256(bytes("solveChallenge(uint256,string)")));
    }

    // This function allows you to safely transfer a NFT to the target address
    function forwardNFT(address nftAddress, uint256 tokenId) private {
        IERC721 nft = IERC721(nftAddress);

        // Ensure that this contract is the owner of the NFT before transferring
        require(
            nft.ownerOf(tokenId) == address(this),
            "Not the owner of this token"
        );

        nft.safeTransferFrom(address(this), i_owner, tokenId);
    }
}
