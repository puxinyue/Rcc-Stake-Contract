
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyContractV2 is Initializable {
    uint public value;
    address public owner; // 新增变量
    
    function initialize(uint _initValue) public initializer {
        value = _initValue;
        owner = msg.sender; // V2 新增初始化逻辑
    }

    function setValue(uint _newValue) public {
        require(msg.sender == owner, "Only owner");
        value = _newValue;
    }
}