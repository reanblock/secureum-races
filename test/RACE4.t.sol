// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { InSecureum } from "../src/Race4.sol";

contract InSecureumTestBase is Test {
    InSecureum token;
    address spender = makeAddr("spender");
    address attacker = makeAddr("attacker");
    uint256 INITIAL_BALANCE = 1000 ether;

    function setUp() public virtual {
        token = new InSecureum("InSecureum", "INS");
        // provide 1000 INS to the test contract to use
        deal(address(token), address(this), INITIAL_BALANCE);
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

contract R4_Q3 is InSecureumTestBase {
    function test_incorrectAllowanceCheckInTransferFrom() public {
        uint256 target = token.balanceOf(address(this));
        // note do not even need to approve spender becuase _allowances is read incorrectly in the contract!

        vm.startPrank(spender);
        assertEq(token.balanceOf(address(this)), target);
        assertEq(token.balanceOf(attacker), 0);

        // note simply pass in the amount to transfer and it will work as long as the 
        // sender account has enough balance however, the spenders allowance is not checked!
        token.transferFrom(address(this), attacker, target);
        
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(attacker), target);
    }

    function test_fuzzUnderflow(uint8 allowance, uint8 target) public {
        // uint8 allowance = 0;
        // uint8 target = 255;
        uint8 amount = target <= allowance ? allowance - target : allowance + 1 + (type(uint8).max - target);
        uint8 result;

        unchecked {
            result = allowance - amount;
        }

        console.log("amount: ", amount);
        console.log("result: ", result);

        assertEq(result, target);
    }
}