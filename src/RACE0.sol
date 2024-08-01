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

contract R0Q4 {
  // Assume other required functionality is correctly implemented
  
  mapping (uint256 => address) addresses;
  bool check; // false by default

  event GetAddress(uint256 id);
  
  modifier onlyIf() {
    if (check) {
      _;
    }
  }

  // in mainnet this would need access control!
  function setCheck(bool _check) public {
    check = _check;
  }
  
  function setAddress(uint id, address addr) public {
    addresses[id] = addr;
  }
  
  function getAddress(uint id) public onlyIf returns (address) {
    emit GetAddress(id);
    return addresses[id];
  }
}