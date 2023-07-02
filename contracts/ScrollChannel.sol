// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./L2Channel.sol";

interface IMessenger {
    /// @notice Return the sender of a cross domain message.
    function xDomainMessageSender() external view returns (address);
}

contract OPChannel is L2Channel {
    address L1Contract;
    IMessenger ovmL2CrossDomainMessenger;

    constructor(address _l1) L2Channel(534352) {
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

    function forceClose(uint256 channelId, uint256 amount1, uint256 amount2) external onlyL1Contract {
        _forceClose(channelId, amount1, amount2);
    }
}