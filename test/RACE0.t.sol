// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {R0Q2, R0Q3, R0Q4, R0Q5} from "../src/Race0.sol";

contract R0Q2Test is Test {
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

        /* 
            call kill function (which calls selfdestruct)
            called in setUp so the transaction can complete
            and the bytecode is removed before test_destroyed
            function is executed.
            
            See discussion here for more details: 
            https://github.com/foundry-rs/foundry/issues/1543
        */ 
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

contract R0Q3Test is Test {
    R0Q3 r0q3;
    address attacker = makeAddr("attacker");
    uint256 depositAmount = 1 ether;
    address owner;

    function setUp() public {
        r0q3 = new R0Q3();
        owner = r0q3.owner();
        address(r0q3).call{value: depositAmount}("");
    }

    function test_anyoneCanCallTransferFunds() public {
        vm.prank(attacker);
        r0q3.transferFunds(payable(attacker), depositAmount);

        assertEq(address(r0q3).balance, 0);
        assertEq(address(attacker).balance, depositAmount);
    }

    function test_transferFundsCanRevert() public {
        vm.expectRevert();
        r0q3.transferFunds(payable(address(this)), depositAmount);
    }

    // only run this test when the onlyAdmin is applied to transferFunds function
    function xtest_onlyAdminCanCallTransferFundsWhenFixed() public {
        vm.prank(attacker);
        vm.expectRevert("unauthorized");
        r0q3.transferFunds(payable(attacker), depositAmount);
        

        vm.prank(owner);
        r0q3.transferFunds(payable(owner), depositAmount);
        assertEq(address(r0q3).balance, 0);
        assertEq(address(owner).balance, depositAmount);       
    }
}

contract R0Q4Test is Test {
    R0Q4 r0q4;
    address testAddr = makeAddr("testAddr");

    function setUp() public {
        r0q4 = new R0Q4();

        // set address id 0 to testAddr
        r0q4.setAddress(0, testAddr);
    }

    function test_getAddressReturnesZeroAddressWhenCheckIsFALSE() public {
        /* 
            check is false (by default) so the code in the getAddress function body
            will not be executed and therefore the default value for address type is returened
        */
        assertEq(r0q4.getAddress(0), address(0x0));
    }
    function test_getAddressReturnesExpectedAddressWhenCheckIsTRUE() public {
        // set the check flag to true
        r0q4.setCheck(true);

        // calling getAddress returnes the expected address
        assertEq(r0q4.getAddress(0), testAddr);
    }
}

contract R0Q5Test is Test {
    R0Q5 r0q5;
    R0Q5Attacker attackContract;
    R0Q5Revert revertContract;
    address attacker = address(0xc3e3a0be380b435c14B6aDB7aB8b8b56eB5Cc6eb);

    function setUp() public {
        r0q5 = new R0Q5();
        attackContract  = new R0Q5Attacker();
        revertContract  = new R0Q5Revert();
    }

    function test_potentialControlledDelegatecallRisk() public {    
        // before calling the delegate restrictedFunction cannot be called 
        vm.prank(attacker);
        vm.expectRevert("unauthorized");
        r0q5.restrictedFunction();

        // call delegate passing the attacers contract to change the owenr address in the target
        r0q5.delegate(address(attackContract));
        
        // now the attacker can call the restrictedFunction without any issues!
        vm.prank(attacker);
        r0q5.restrictedFunction();
    }

    function test_delegatecallReturnValueIsNotChecked() public {
        // calling delegate with a contract definition of setDelay that reverts
        // will not cause the top level call to revert
        r0q5.delegate(address(revertContract));
    }

    function test_delegateDoesNotCheckForContractExistenceAtAddr() public {
        // call delegate with an address that does not have contract deployed 
        // will NOT revert at any level in the call stack
        r0q5.delegate(address(0x0));
    }
}

contract R0Q5Attacker {
    address private slot0Placeholder; // slot 0

    function setDelay(uint256 _value) public {
        slot0Placeholder = address(0xc3e3a0be380b435c14B6aDB7aB8b8b56eB5Cc6eb);
    }
}

contract R0Q5Revert {
    function setDelay(uint256 _value) public {
        revert("call to setDelay reverted");
    }
}