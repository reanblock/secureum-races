// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma abicoder v2;

import { Test, console } from "forge-std/Test.sol";
import { InSecureumApe } from "../src/Race7.sol";

// NOTE Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8 (all questions!) do not require tests

contract InSecureumApeTestBase is Test {
    InSecureumApe nft;

    function setUp() public virtual {
        nft = new InSecureumApe("InSecureumApe", "ISAPE", 1000, 1);
    }

    function test_deployed() public {
        console.log(address(nft));
    }
}