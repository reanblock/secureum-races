// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
import {console} from "forge-std/Test.sol";

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

contract R0Q5 {
  // Assume other required functionality is correctly implemented
  address private owner = address(0x78c4e41228C2874C436fA57108dC63D9497E5be5);
  
  modifier onlyAdmin {
    // Assume this is correctly implemented
    require(msg.sender == owner, "unauthorized");
    _;
  }

  function restrictedFunction() onlyAdmin external {
    // Assume this is correctly implemented
  }
  
  function delegate(address addr) external {
    /* 
      uncomment require to check if there is deployed bytecode at the addr
      this is needed because success will be true even if addr does not point to a contract
    */ 
    // require(addr.code.length > 0, "no contract at addr");
    (bool success, ) = addr.delegatecall(abi.encodeWithSignature("setDelay(uint256)", 0));
    // console.log(success);
  }
}