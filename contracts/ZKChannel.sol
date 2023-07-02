// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./L2Channel.sol";

contract OPChannel is L2Channel {
    address L1Contract;

    constructor(address _l1) L2Channel(324) {
        L1Contract = _l1;
    }

    modifier onlyL1Contract() {
        require(
            msg.sender == L1Contract,
            "Not allowed!"
        );
        _;
    }

    function forceClose(uint256 channelId, uint256 amount1, uint256 amount2) external onlyL1Contract {
        _forceClose(channelId, amount1, amount2);
    }
}