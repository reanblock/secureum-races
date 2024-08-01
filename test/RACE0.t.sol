// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {R0Q2} from "../src/Race0.sol";

contract Race0Test is Test {
    R0Q2 public r0q2;

    function setUp() public {
        // deploy the contract
        r0q2 = new R0Q2();

        // check the balance of the 0x0 address
        assertEq(address(0x0).balance, 0);

        // send eth to the contract
        address(r0q2).call{value: 1 ether}("");

        // check contract baalance 
        assertEq(address(r0q2).balance, 1 ether);

        // check the bytecode
        assertGt(address(r0q2).code.length, 0);

        // call kill function (which calls selfdestruct)
        r0q2.kill();
    }

    function test_destroyed() public {
        // check contract balance is zero
        assertEq(address(r0q2).balance, 0);

        // check address zero has 1 ether (sent from selfdestruct)
        assertEq(address(0x0).balance, 1 ether);

        // check the bytecode size is zero
        assertEq(address(r0q2).code.length, 0);

        // call kill function reverts since bytecode is erased
        vm.expectRevert();
        r0q2.kill();
    }
}
