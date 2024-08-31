// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import {console} from "forge-std/Test.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// R0Q2 - RACE0, QUESTION2
contract R0_Q2 {
  // Assume other required functionality is correctly implemented
  function kill() public {
    selfdestruct(payable(0x0));
  }

  // to send eth during test
  receive() payable external {}
}

// R0Q3 - RACE0, QUESTION3
contract R0_Q3 {
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
contract R0_Q4 {
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
contract R0_Q5 {
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
contract R0_Q7 {
  // Assume other required functionality is correctly implemented
  uint256 private constant secret = 123;
  
  function diceRoll() external view returns (uint256) {
    return (((block.timestamp * secret) % 6) + 1);
  }
}

contract R0_Q8 {
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

contract R0_Q9 {
  // Assume other required functionality is correctly implemented
  uint256 private constant MAX_FUND_RAISE = 100 ether;
  mapping (address => uint256) contributions;
  function contribute() external payable {
    require(address(this).balance != MAX_FUND_RAISE);
    contributions[msg.sender] += msg.value;
  }
}

contract R0_Q10 {
  // Assume other required functionality is correctly implemented

  function callMe (address target) external {
    (bool success, ) = target.call("");
    console.log(success);
    require(success);
  }
}

contract R0_Q11 {
  // Assume other required functionality is correctly implemented
  // Assume admin is set correctly to contract deployer in constructor
  address public admin = 0x6C328AFB6172025FD0e6eF426f1c56624a00432C;
  
  function setAdmin (address _newAdmin) external {
    admin = _newAdmin;
  }
}

contract R0_Q11_Ownable2Step is Ownable2Step {
  constructor() Ownable(msg.sender) {}
}

contract R0_Q12 {
  // Assume other required functionality is correctly implemented 
  address admin;
  address payable public pool;
  constructor(address _admin) {
    admin = _admin;
  } 

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }
  
  function setPoolAddress(address payable _pool) external onlyAdmin {
    pool = _pool;
  }

  function addLiquidity() payable external {
    pool.transfer(msg.value);
  }
}

contract R0_Q13 is Initializable, UUPSUpgradeable {
  // Assume other required functionality is correctly implemented
  
  address public admin;
  uint256 public rewards = 10;
  
  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }
  
  // NOTE: to prevent multiple calls of initialize use this:
  // function initialize (address _admin) initializer external {
  function initialize (address _admin) external {
    require(_admin != address(0));
    admin = _admin;
  }
  
  function setRewards(uint256 _rewards) external onlyAdmin {
    rewards = _rewards;
  }

  // _authorizeUpgrade is required from inheriting UUPSUpgradeable
  function _authorizeUpgrade(address) internal override onlyAdmin {}
}

contract R0_Q13_V2 is Initializable, UUPSUpgradeable {
  address public admin;
  uint256 public rewards;
  
  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }
  
  function initialize () initializer external {
    // nothing to do since we keep the same admin
  }
  
  // remove setRewards function
  // function setRewards(uint256 _rewards) external onlyAdmin {
  //   rewards = _rewards;
  // }

  function someNewFeature() external returns(string memory) {
    return "hello from new feature!";
  }

  function _authorizeUpgrade(address) internal override onlyAdmin {}
}

contract R0_Q14 {
  // Assume other required functionality is correctly implemented
  address admin;
  address token;
  constructor(address _admin, address _token) {
    require(_admin != address(0));
    require(_token != address(0));
    admin = _admin;
    token = _token;
  }
  
  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }
  
  function payRewards(address[] calldata recipients, uint256[] calldata amounts) external onlyAdmin {
    for (uint i; i < recipients.length; i++) {
        IERC20(token).transfer(recipients[i], amounts[i]);
    }
  }
}