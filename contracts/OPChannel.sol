// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./L2Channel.sol";

interface IMessenger {
    function xDomainMessageSender() external returns (address);
}

contract OPChannel is L2Channel {
    address L1Contract;
    IMessenger ovmL2CrossDomainMessenger;

    constructor(address _l1) L2Channel(10) {
        L1Contract = _l1;
    }

    modifier onlyL1Contract() {
        require(
            msg.sender == address(ovmL2CrossDomainMessenger)
            && ovmL2CrossDomainMessenger.xDomainMessageSender() == L1Contract,
            "Not allowed!"
        );
        _;
    }
}