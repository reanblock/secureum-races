// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { Proxy, Mastercopy } from "../src/Race9.sol";

// NOTE Q1, Q2, Q3, Q6, Q7, Q8 do not require tests

contract MastercopyProxyTestBase is Test {
    Proxy proxy;
    Mastercopy masterProxy;

    function setUp() public virtual {
        proxy = new Proxy();
        // wrap the proxy in the Mastercopy to make it 
        // easier to call functions on it in the tests
        masterProxy = Mastercopy(address(proxy));
    }
}
contract R9_Q4 is MastercopyProxyTestBase {
    function test_callIncrease() public {
        // counter should start at 0
        assertEq(masterProxy.counter(), 0);

        // call increase via the proxy
        masterProxy.increase();

        // after calling increase it should be 1
        assertEq(masterProxy.counter(), 1);
    }
}
contract R9_Q5 is MastercopyProxyTestBase {
    function test_callDecreaseShouldNOTWork() public {
        masterProxy.increase();
        assertEq(masterProxy.counter(), 1);
        // if called directly thought the interfce it will revert because the proxy 
        // did not correctly register the decrease function so we make a low level call instead
        // masterProxy.decrease(); // this will revert with "EvmError: Revert"
        bytes memory data = abi.encodeWithSelector(masterProxy.decrease.selector, "");
        (bool success, ) = address(proxy).call(data);
        // returns success true since all calls that are made to addresses that do not have runtime bytecode, 
        // will succeed without returning any data.
        assertTrue(success);

        // will still be 1 because the call to decrease was on the zero address and not the impl
        assertEq(masterProxy.counter(), 1);
    }
}