// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

contract InSecureumDAO is Pausable, ReentrancyGuard {
    // Assume that all functionality represented by ... below is implemented as expected
    address public admin;
    mapping (address => bool) public members;
    mapping (uint256 => uint8[]) public votes;
    mapping (uint256 => uint8) public winningOutcome;
    uint256 memberCount = 0;
    uint256 membershipFee = 1000;
    
    modifier onlyWhenOpen() {
        require(address(this).balance > 0, 'InSecureumDAO: This DAO is closed');
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    modifier voteExists(uint256 _voteId) {
        // Assume this correctly checks if _voteId is present in votes
        // ...
        _;
    }

    constructor (address _admin) {
      // below require staement fixed so tests can run
      // require(_admin == address(0));
      require(_admin != address(0), "zero admin address");
      admin = _admin;
    }

    function openDAO() external payable onlyAdmin {
        // Admin is expected to open DAO by making a notional deposit
        // ...
    }

    function join() external payable onlyWhenOpen nonReentrant {
        require(msg.value == membershipFee, 'InSecureumDAO: Incorrect ETH amount');
        members[msg.sender] = true;
        // ...
    }

    function createVote(uint256 _voteId, uint8[] memory _possibleOutcomes) external onlyWhenOpen whenNotPaused {
        votes[_voteId] = _possibleOutcomes;
        // ...
    }

    function castVote(uint256 _voteId, uint8 _vote) external voteExists(_voteId) onlyWhenOpen whenNotPaused {
        // ...
    }

    function getWinningOutcome(uint256 _voteId) public view returns (uint8) {
        // ...
    }

    function setMembershipFee(uint256 _fee) external onlyAdmin {
        membershipFee = _fee;
    }

    function removeAllMembers() external onlyAdmin {
        delete members[msg.sender];
    }
}

/*
    Example of the InSecureumDAO contract that uses a 
    commit / reveal scheme for voting (for Race 2 Question 5)
*/
contract InSecureumDAOCommitReveal is InSecureumDAO {
    mapping(address => bytes32) public hashedVotes;
    mapping(uint8 => uint8) public voteCount;
    constructor(address admin) InSecureumDAO(admin) {}

    // voters should call the hashVote function off-chain and should use a 
    // securly off-chain and off-line generated random salt
    function hashVote(uint8 vote, uint256 salt) public view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, vote, salt));
    }

    function commitVote(bytes32 hashedVote) external {
        require(block.timestamp < 10, "voting ended");
        hashedVotes[msg.sender] = hashedVote;
    }

    function revealVote(uint8 vote, uint256 salt) external returns(bool) {
        require(block.timestamp > 10, "voting not ended");
        require(hashVote(vote, salt) == hashedVotes[msg.sender], "invalid reveal");
        // NOTE: can also add a require statement to prevent calling revealVote more than once but 
        // this is intentially left out to focus on the commit reveal voting mechanism

        voteCount[vote] += 1;
        return true;
    }
}