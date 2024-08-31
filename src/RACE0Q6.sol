// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
import "@openzeppelin/contracts-solc-0.7/utils/ReentrancyGuard.sol";
// which works with 0.7.0

import {console} from "forge-std/Test.sol";

contract R0_Q6 is ReentrancyGuard {
  // Assume other required functionality is correctly implemented
  // For e.g. users have deposited balances in the contract
  // Assume nonReentrant modifier is always applied
  
  mapping (address => uint256) public balances;
  
  function withdraw(uint256 amount) external nonReentrant {
    msg.sender.call{value: amount}("");
    console.log("balances[msg.sender]: ", balances[msg.sender]);
    
    balances[msg.sender] -= amount;

    console.log("balances[msg.sender]: ", balances[msg.sender]);
    console.log("withdraw: ", amount);
  }

  receive() external payable {}
}