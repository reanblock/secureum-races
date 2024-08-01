// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {R0Q6} from "../src/RACE0Q6.sol";

contract R0Q6Test is Test { 
    R0Q6 r0q6;

    function setUp() public {
        r0q6 = new R0Q6();
    }

    function test_deployed() public {
        console.log(address(r0q6));
    }

    function test_withdraw() public {
        r0q6.withdraw(1 ether);
    }
}