// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { InSecureum } from "../src/Race5.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract InSecureumTestBase is Test {
    InSecureum token;
    function setUp() public virtual {
        token = new InSecureum("https://somedomain.com");
    }
}

// NOTE Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8 (all the questions!)  do not require tests

contract R5 is InSecureumTestBase {
    function test_deployed() public {
        console.log(address(token));
        console.log(token.uri(0));
    }

    function test_supportsInterface() public {
        // some random interface (bytes4) should not be supported
        assertFalse(token.supportsInterface(0x11223344));
        
        // the IERC1155 interface should be suported
        // console.logBytes4(type(IERC1155).interfaceId);
        assertTrue(token.supportsInterface(type(IERC1155).interfaceId));
    }
}
