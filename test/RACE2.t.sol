// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { InSecureumDAO, InSecureumDAOCommitReveal } from "../src/Race2.sol";

contract InSecureumDAOTestBase is Test {
    InSecureumDAO dao;
    address admin = makeAddr("admin");

    function setUp() public virtual {
        dao = new InSecureumDAO(admin);
    }
}

contract R2_Q1 is InSecureumDAOTestBase {
    function test_ZeroEtherBalanceInDao() public {
        // the initial balance of the DAO should be 0
        assertEq(address(dao).balance, 0);
    }
    function test_UnableToJoinWhenDaoClosed() public {
        // try calling join which should revert since onlyWhenOpen modifier will fail
        vm.expectRevert('InSecureumDAO: This DAO is closed');
        dao.join();
    }

    function test_CanJoinWhenDaoClosedByPayingMembershipFee() public {
        // note its possible to join even when the DAO is 'closed' (i.e. starts with a balance of 0)
        // by sending the membershipFee (1000 wei) to the join function. This causes the onlyWhenOpen
        // modifier to pass because at that point the contract balance is > 0
        dao.join{value: 1000}();

        // assert we are a member
        assertTrue(dao.members(address(this)));
    }
}

contract ImmediateSelfDestruct {
    constructor(address payable target) payable {
        selfdestruct(target);
    }
}

contract InSecureumDAOTestForceEther is InSecureumDAOTestBase {
    // override the setUp function to deploy the ImmediateSelfDestruct contract
    // which will force ether into the DAO. Useful for any tests that need this.
    function setUp() public override {
        super.setUp();

        new ImmediateSelfDestruct{value: 1 ether}(payable(address(dao)));
    }
}

contract R2_Q1_ForceEther is InSecureumDAOTestForceEther {
    function test_DAOCanBeOpenedByAnyoneByMakingAnEtherDepositToTheContract() public {
        /*
            While the payable openDAO() function is protected by the correctly implemented 
            onlyAdmin modifier, it is always possible to force send Ether into a contract 
            via selfdestruct(). 
            
            The onlyWhenOpen() modifier only checks for the contracts own 
            balance which can be bypassed by doing that. 
        */

        // because the ImmediateSelfDestruct contract forced Ether into the DAO contract 
        // without having to call any payable functions in the DAO contract.
        assertEq(address(dao).balance, 1 ether);
    }
}

// NOTE Q2, Q3, Q4 does not require tests


/*
    Test for the InSecureumDAO contract that uses a 
    commit / reveal scheme for voting
*/
contract R2_Q5 is InSecureumDAOTestBase {
    InSecureumDAOCommitReveal daoCommitReveal;
    uint8 vote = 1;
    // voter would generate this random salt securly off-chain and off-line
    uint256 salt = 736437287346273456213;

    function setUp() public override {
        daoCommitReveal = new InSecureumDAOCommitReveal(admin) ;
    }

    function test_commitAndRevelVote() public {
        bytes32 hashedVote = daoCommitReveal.hashVote(vote, salt);
        daoCommitReveal.commitVote(hashedVote);

        // assert the hashed vote has been recoreded in the dao
        assertEq(daoCommitReveal.hashedVotes(address(this)), hashedVote);
        
        // cannot reveal before voting period has ended
        vm.expectRevert("voting not ended");
        daoCommitReveal.revealVote(vote, salt);

        // move time to end of voting period
        vm.warp(11);
        // any other votes will not be true for our voter address (wrong vote, correct salt)
        vm.expectRevert("invalid reveal");
        assertFalse(daoCommitReveal.revealVote(99, salt));
        // any other votes will not be true for our voter address (correct vote, wrong salt)
        vm.expectRevert("invalid reveal");
        assertFalse(daoCommitReveal.revealVote(vote, 99));
        // before reveal the vote count for vote should be 0
        assertEq(daoCommitReveal.voteCount(vote), 0);
        // reveal our vote
        assertTrue(daoCommitReveal.revealVote(vote, salt));
        // check vote count again since after reveal it should be 1
        assertEq(daoCommitReveal.voteCount(vote), 1);
    }
}