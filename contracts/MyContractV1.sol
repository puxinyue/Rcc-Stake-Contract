// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyContractV1 is Initializable {
    uint public value;
    
    function initialize(uint _initValue) public initializer {
        value = _initValue;
    }

    function setValue(uint _newValue) public {
        value = _newValue;
    }
}
