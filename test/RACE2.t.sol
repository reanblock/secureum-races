// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { InSecureumDAO } from "../src/Race2.sol";

contract InSecureumDAOTestBase is Test {
    InSecureumDAO dao;
    address admin = makeAddr("admin");

    function setUp() public {
        dao = new InSecureumDAO(admin);
    }
}

contract R2_Q1 is InSecureumDAOTestBase {
    function test_deployed() public {
        console.log(address(dao));
    }
}