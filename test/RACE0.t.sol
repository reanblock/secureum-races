// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {R0Q2, R0Q3, R0Q4, R0Q5, R0Q7} from "../src/Race0.sol";

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

contract R0Q7Test is Test {
    R0Q7 r0q7;

    function setUp() public {
        r0q7 = new R0Q7();

        // for more realistic value of block.timestamp since in tests it defaults to 1
        vm.warp(1722591648); 
    }

    /*
        "The private variable secret is not really hidden from users"

        Since `secret` is a private constant we cannot 
        
            - call `r0q7.secret()` (because its private)
            - call `vm.load(address(r0q7), 0)` (becuase it is a constant which is stored inline
            in the bytecode).

        This meanss the compiled bytecode for R0Q7 esstially looks like the following (NOTE: the 
        definition of `secret` is removed and the variable is replaced inline with the value 123):

        contract R0Q7 {
            function diceRoll() external view returns (uint256) {
                return (((block.timestamp * 123) % 6) + 1);
            }
        }

        Therefore, the way to extract secret value is from the bytecode. We can
        use the following steps:

            - Extract the Bytecode: `address(r0q7).code`
            - Analyze the Bytecode: we can use https://www.evm.codes/playground for this
            - Extract the Constant: look for where the value is pushed to the stack. In this example, 123 (0x7b)
            is pushd the stack just before the block.timestamp (TIMESTAMP) is pushed to the stack:

            PUSH1	    7b
            TIMESTAMP

        The full compiled bytecode for R0Q7 is (go play around with it!):

        0x6080604052348015600f57600080fd5b506004361060285760003560e01c806370bddc8014602d575b600080fd5b60336045565b60405190815260200160405180910390f35b600060066052607b42607e565b605a9190609a565b606390600160bb565b905090565b634e487b7160e01b600052601160045260246000fd5b600081600019048311821515161560955760956068565b500290565b60008260b657634e487b7160e01b600052601260045260246000fd5b500690565b6000821982111560cb5760cb6068565b50019056fea26469706673582212203b6ba86e939984b6497b23faf4d2b4e55aa58fd0af1c56c9a9a932d2a69d6bb664736f6c634300080d0033
    */
    function test_privateVariableSecretIsNotReallyHiddenFromUsers() public {
        // call `r0q7.secret()` (because its private)
        // Results in the folloing compile time error: 
        // Error (9582): Member "secret" not found or not visible after argument-dependent lookup in contract R0Q7.
        // r0q7.secret();

        // low level call will just return null (0x)
        (bool success, bytes memory dataFromCall) = address(r0q7).call(abi.encodeWithSignature("secret()"));
        assertEq(success, false);
        assertEq(dataFromCall, "");

        // call `vm.load(address(r0q7), 0)` will return empty slot data (0x0000...)
        bytes32 dataFromLoad = vm.load(address(r0q7), 0);
        assertEq(dataFromLoad, 0x0000000000000000000000000000000000000000000000000000000000000000);

    }

    function test_blockTimestampIsAnInsecureSourceOfRandomness() public {
        // if the diceRoll is part of a game then its easy to 'guess' the outcome
        // by running the same code in the diceRoll function before calling it:
        uint256 calculatedGuess = ((block.timestamp * 123) % 6) + 1;
        assertEq(calculatedGuess, r0q7.diceRoll());
        console.log(calculatedGuess);

        // skip time forward by 3455 seconds and try again (should always 'guess' correctly!)
        skip(3455);

        calculatedGuess = ((block.timestamp * 123) % 6) + 1;
        assertEq(calculatedGuess, r0q7.diceRoll());

        console.log(calculatedGuess);
    }

    function test_logicOfDiceRollIsBrokenAsItReturnsOnly1Or4() public {
        // review the comment "The logic of diceRoll() is broken as it returns only 1 or 4"
        // one solution is to remove the secret factor altogether
        assertEq(fixedRollDiceFunction(), 1);
        skip(1); // moves block.timestamp forward by 1 second 
        assertEq(fixedRollDiceFunction(), 2);
        skip(1);
        assertEq(fixedRollDiceFunction(), 3);
        skip(1);
        assertEq(fixedRollDiceFunction(), 4);
        skip(1);
        assertEq(fixedRollDiceFunction(), 5);
        skip(1);
        assertEq(fixedRollDiceFunction(), 6);
        skip(1);
        assertEq(fixedRollDiceFunction(), 1);
        skip(1);
        assertEq(fixedRollDiceFunction(), 2);
        // etc...
    }

    /* 
        fixedRollDiceFunction is an example of a function that works as expected
        it returns a number between 1 and 6 based on the current block.timestamp
        the fix is to remove the multiplication of block.timestamp by secret 
    */ 
    //
    function fixedRollDiceFunction() public returns (uint256) {
        return ((block.timestamp) % 6) + 1;
    }
}
