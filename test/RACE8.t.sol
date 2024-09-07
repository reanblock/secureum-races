// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { ERC721, ERC721TokenReceiver } from "../src/Race8.sol";

// NOTE Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8 (all questions!) do not require tests

// implementation contracts for testing
contract TestERC721Impl is ERC721 {
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}
    function tokenURI(uint256 id) public view override returns (string memory) {
        return "https://token-cdn-domain/{id}.json";
    }
}

contract TestERC721TokenReceiverImpl is ERC721TokenReceiver {}

contract ERC721ImplTestBase is Test {
    TestERC721Impl nft;
    TestERC721TokenReceiverImpl receiver;

    function setUp() public virtual {
        nft = new TestERC721Impl("MyNFT", "MNFT");
        receiver = new TestERC721TokenReceiverImpl();
    }

    function test_deployed() public {
        console.log("NFT address: ", address(nft));
        console.log("Receiver address: ", address(receiver));
    }
}