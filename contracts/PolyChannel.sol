// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./L2Channel.sol";

contract PolyChannel is L2Channel {
    address L1Contract;
    address l2Bridge;

    constructor(address _l1) L2Channel(324) {
        L1Contract = _l1;
    }

    modifier onlyL1Contract(address caller) {
        require(
            msg.sender == l2Bridge && caller == L1Contract,
            "Not allowed!"
        );
        _;
    }

    function forceClose(address caller, uint256 channelId, uint256 amount1, uint256 amount2) external onlyL1Contract(caller) {
        _forceClose(channelId, amount1, amount2);
    }
}