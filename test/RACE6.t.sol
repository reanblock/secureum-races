// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { InSecureumLand } from "../src/Race6.sol";

// for testing MerkleProof library
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Mock ERC20 for using in test
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

// NOTE Q2, Q3, Q4, Q5, Q6, Q7, Q8 do not require tests

contract InSecureumLandTestBase is Test {
    InSecureumLand nft;
    address operator = makeAddr("operator");
    address contributor = makeAddr("contributor");
    address vrfCoordinator = makeAddr("vrfCoordinator");
    address linkTokenAddress = makeAddr("linkTokenAddress");

    // KYC Addresses
    address kycAddress0 = makeAddr("kycAddress0");
    address kycAddress1 = makeAddr("kycAddress1");
    address kycAddress2 = makeAddr("kycAddress2");
    address kycAddress3 = makeAddr("kycAddress3");

    // NON KYC Addresses
    address nonKycAddress0 = makeAddr("nonKycAddress0");
    address nonKycAddress1 = makeAddr("nonKycAddress1");

    ERC20Mock erc20Mock;

    function setUp() public virtual {
        // deploy mock erc20 
        erc20Mock = new ERC20Mock();

        InSecureumLand.ContractAddresses memory addresses = InSecureumLand.ContractAddresses({
            alphaContract: 0x1111111111111111111111111111111111111111,
            betaContract: 0x2222222222222222222222222222222222222222,
            tokenContract: address(erc20Mock)
        });

        InSecureumLand.LandAmount memory landAmount = InSecureumLand.LandAmount({
            alpha: 1,
            beta: 2,
            publicSale: 3,
            future: 4
        });

        InSecureumLand.ContributorAmount memory contributor1 = InSecureumLand.ContributorAmount({
            contributor: contributor,
            amount: 4
        });

        InSecureumLand.ContributorAmount[] memory contributors = new InSecureumLand.ContributorAmount[](1);
        contributors[0] = contributor1;

        bytes32 vrfKeyHash = keccak256(abi.encodePacked("vrfKeyHashMock"));
        uint256 vrfFee = 0;
        
        nft = new InSecureumLand("InLand", 
                                 "INL",
                                 addresses,
                                 landAmount,
                                 contributors,
                                 vrfCoordinator,
                                 linkTokenAddress,
                                 vrfKeyHash,
                                 vrfFee,
                                 operator) ;

        // approve nft as spnder for kycAddress0 ERC20Mock
        deal(address(erc20Mock), kycAddress0, 100 ether);
        vm.prank(kycAddress0);
        erc20Mock.approve(address(nft), type(uint256).max);
    }
}

contract InSecureumLandMerkleTree is InSecureumLandTestBase {
     /*
        Normally Merkle Trees are generated off chian using an external library
        However, sinde we are in a test environment we can use this basic Soldiity implemntation
    */
    bytes32[] public leafs;
    bytes32[] public level2;

    // merke root and merkle proof 
    bytes32 kycMerkleRoot;
    bytes32[] merkleProof;

    function setUp() public virtual override {
        super.setUp();
        // create merkle root for all the KYC addresses
        kycMerkleRoot = createMerkleRoot();
        // create merke proof for kycAddress0
        merkleProof = createMerkeProof();
    }

    /*
        Creates a merkle tree structure for KYC addresses as leaves.

                                root
                       ___________|____________ 
                      |                         |
                 __h(l0,l1)__               ___h(l2,l3)___
                |           |              |              | 
                l0          l1            l2              l3
        h(kycAddress0) h(kycAddress1) h(kycAddress2) h(kycAddress3)
    */
    function createMerkleRoot() internal returns (bytes32 root) {
        // Calculate the hash values of leaf nodes from a list of addresses.
        leafs.push(keccak256(abi.encodePacked(kycAddress0)));
        leafs.push(keccak256(abi.encodePacked(kycAddress1)));
        leafs.push(keccak256(abi.encodePacked(kycAddress2)));
        leafs.push(keccak256(abi.encodePacked(kycAddress3)));

        // Calculate the hash values of the second level.
        level2.push(keccak256(abi.encodePacked(leafs[0], leafs[1])));
        level2.push(keccak256(abi.encodePacked(leafs[2], leafs[3])));

        // return the merkle root for the kyc addresses added to the tree
        root = keccak256(abi.encodePacked(level2[1], level2[0]));
    }

    /*
        Creates a proof to use for leaf 0 (kycAddress0). Merkle Proofs only 
        require alternating sides of tree nodes to reach the merkle root.

        Given the user provides the value of l0 then only two nodes: 
        l1, and h(l2,l3) are required for the proof (marked with ✓  below):

                                root
                       ___________|____________ 
                      |                         |
                   h(l0,l1)                   h(l2,l3)
                 _____|_____                _____(✓)______
                |           |              |              | 
                l0          l1            l2              l3
            (provided)      (✓)
    */
    function createMerkeProof() internal returns(bytes32[] memory proof) {
        // NOTE this is specifically the proof for leafs index 0 (kycAddress0)
        proof = new bytes32[](2);
        proof[0] = leafs[1];
        proof[1] = level2[1];
    }

    /* 
        using the merkle proof for KYC address 0 we can proove that the address exists
        in the merkle tree that has the kycMerkleRoot by using the MerkleProof.verify library function
    */
    function test_merkleProofVerify() public {
        bool addressVerified = MerkleProof.verify(merkleProof, kycMerkleRoot, keccak256(abi.encodePacked(kycAddress0)));
        assertTrue(addressVerified);
    }
}

contract R6_Q1 is InSecureumLandMerkleTree {
    function setUp() public override {
        super.setUp();

        bool isKycCheckRequired = true;
        uint256 maxMintPerAddress = 2;
        uint256 maxMintPerTx = 2;
        uint256 publicSaleStartPrice = 2 ether;
        uint256 publicSaleEndingPrice = 1 ether;
        uint256 publicSalePriceLoweringDuration = 3600;

        vm.startPrank(operator);
        nft.startPublicSale(publicSalePriceLoweringDuration, 
                            publicSaleStartPrice, 
                            publicSaleEndingPrice, 
                            maxMintPerTx, 
                            maxMintPerAddress, 
                            isKycCheckRequired);

        nft.setKycMerkleRoot(kycMerkleRoot); 
        vm.stopPrank();  
    }

    function test_mintLandsWithKYCAddress() public {
        // non KYC addreses will be rejected
        vm.prank(nonKycAddress0);
        vm.expectRevert("Sender address is not in KYC allowlist");
        nft.mintLands(1, merkleProof);

        // when calling from a KYC address and valid merkle proof, it works!
        vm.prank(kycAddress0);
        nft.mintLands(1, merkleProof);

    }
}