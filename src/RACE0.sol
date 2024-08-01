// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// R0Q2 - RACE0, QUESTION2
contract R0Q2 {
  // Assume other required functionality is correctly implemented
  function kill() public {
    selfdestruct(payable(0x0));
  }

  // to send eth during test
  receive() payable external {}
}

// R0Q3 - RACE0, QUESTION3
contract R0Q3 {
  address public owner = address(0x39b7A42Fc45A5c669D980161346953e48154682c);
  // Assume other required functionality is correctly implemented
  
  modifier onlyAdmin() {
    // Assume this is correctly implemented
    require(msg.sender == owner, "unauthorized");
    _;
  }
  
  function transferFunds(address payable recipient, uint amount) public {
    recipient.transfer(amount);
  }

  // to send eth during test
  receive() payable external {}
}