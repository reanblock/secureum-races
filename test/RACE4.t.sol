// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { InSecureum } from "../src/Race4.sol";

contract InSecureumTestBase is Test {
    InSecureum token;

    function setUp() public virtual {
        token = new InSecureum("InSecureum", "INS");
    }
}

// NOTE Q1, Q2 do not require tests

contract R4 is InSecureumTestBase {
    function test_deployed() public {
        console.log(address(token));
        console.log(token.name());
        console.log(token.symbol());
    }
}