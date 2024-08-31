// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma abicoder v2;

import { Test, console } from "forge-std/Test.sol";
import { InSecureumToken } from "../src/Race1.sol";

contract InSecureumTokenTest is Test {
    InSecureumToken inSecureumToken;
    function setUp() public {
        inSecureumToken = new InSecureumToken();
    }

    function test_deployment() public {
        console.log(address(inSecureumToken));
    }
}