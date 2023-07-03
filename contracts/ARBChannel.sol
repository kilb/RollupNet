// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./L2Channel.sol";

contract ARBChannel is L2Channel {

    address public L1Contract;

    constructor(address _l1) L2Channel(42161) {
        L1Contract = _l1;
    }

    modifier onlyL1Contract() {
        require(undoL1ToL2Alias(msg.sender) == L1Contract, "ONLY_COUNTERPART_CONTRACT");
        _;
    }

     function forceClose(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) external onlyL1Contract {
        _forceClose(channelId, owner1, owner2, amount1, amount2);
    }

    function undoL1ToL2Alias(address L1_Contract_Address) public pure returns (address) {
        return address(uint160(L1_Contract_Address) + uint160(0x1111000000000000000000000000000000001111));
    }

}


