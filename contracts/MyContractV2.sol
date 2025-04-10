// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyContractV2 is Initializable {
    uint public value;
    address public owner;
    bool private initializedV2;
    
    function initialize(uint _initValue) public initializer {
        value = _initValue;
    }
   
   //添加迁移函数
    function migrateToV2() public {
        require(!initializedV2, "Already migrated");
        owner = msg.sender;
        initializedV2 = true;
    }

    function setValue(uint _newValue) public {
        require(msg.sender == owner, "Only owner");
        value = _newValue;
    }
}