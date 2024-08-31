// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma abicoder v2;

import { Test, console } from "forge-std/Test.sol";
import { InSecureumToken } from "../src/Race1.sol";

contract R1_Q1 is Test {
    InSecureumToken token;
    function setUp() public {
        token = new InSecureumToken();
    }

    function test_lockedEther() public {
        // buy 10 tokens
        token.buy{value: 1 ether}(10);

        assertEq(token.balances(address(this)), 10);

        assertEq(address(token).balance, 1 ether);

        /* 
        The only public functions available on the token are
        
        token.buy(desired_tokens);
        already used in this test. only send ether TO the contract.
        
        token.safeAdd(a, b);
        this is a pure function so cannot be used to transfer ether

        token.transfer(to, amount);
        the transfer function only performs internal accounting 
        and does not transfer ether out of the contract

        Since there are no more public functions available the 
        Ether is therefore locked in the contract!
        */ 
    }
}