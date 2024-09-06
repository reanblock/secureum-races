// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { InSecureum } from "../src/Race5.sol";

contract InSecureumTestBase is Test {
    InSecureum token;
    function setUp() public virtual {
        token = new InSecureum("https://somedomain.com");
    }
}

// NOTE Q1, Q2, Q3 do not require tests

contract R5 is InSecureumTestBase {
    function test_deployed() public {
        console.log(address(token));
        console.log(token.uri(0));
    }
}
