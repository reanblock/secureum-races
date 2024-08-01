// R0Q2 - RACE0, QUESTION2

pragma solidity 0.8.13;
contract R0Q2 {
  // Assume other required functionality is correctly implemented
  function kill() public {
    selfdestruct(payable(0x0));
  }

  // to send eth during test
  receive() payable external {}
}