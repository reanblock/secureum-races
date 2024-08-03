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

// R0Q4 - RACE0, QUESTION4
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

// R0Q5 - RACE0, QUESTION5
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

// R0Q6 - RACE0, QUESTION6 -> refer to ./src/RACE0Q6.sol

// R0Q7 - RACE0, QUESTION7
contract R0Q7 {
  // Assume other required functionality is correctly implemented
  uint256 private constant secret = 123;
  
  function diceRoll() external view returns (uint256) {
    return (((block.timestamp * secret) % 6) + 1);
  }
}

contract R0Q8 {
  // Assume other required functionality is correctly implemented
  // Contract admin set to deployer in constructor (not shown)

  // hardcode admin address for test
  address public admin = 0x6C328AFB6172025FD0e6eF426f1c56624a00432C;
  
  modifier onlyAdmin {
    require(tx.origin == admin);
    _;
  }
  
  function emergencyWithdraw() external payable onlyAdmin {
    payable(msg.sender).transfer(address(this).balance);
  }

  // to directly receive eth during tests
  receive() external payable {}
}

contract R0Q9 {
  // Assume other required functionality is correctly implemented
  uint256 private constant MAX_FUND_RAISE = 100 ether;
  mapping (address => uint256) contributions;
  function contribute() external payable {
    require(address(this).balance != MAX_FUND_RAISE);
    contributions[msg.sender] += msg.value;
  }
}