// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./L2Channel.sol";

interface IMessenger {
    /// @notice Return the sender of a cross domain message.
    function xDomainMessageSender() external view returns (address);
}

contract ScrollChannel is L2Channel {
    address public L1Contract;
    // testnet: 0xb75d7e84517e1504C151B270255B087Fd746D34C
    // or testnet: 0x32139B5C8838E94fFcD83E60dff95Daa7F0bA14c
    IMessenger public ovmL2CrossDomainMessenger;

    constructor(address _l1) L2Channel(534352) {
        L1Contract = _l1;
        ovmL2CrossDomainMessenger = IMessenger(0x32139B5C8838E94fFcD83E60dff95Daa7F0bA14c);
    }

    modifier onlyL1Contract() {
        require(
            msg.sender == address(ovmL2CrossDomainMessenger),
            "Invalid sender!"
        );
        require(
            ovmL2CrossDomainMessenger.xDomainMessageSender() == L1Contract,
            "Not allowed!"
        );
        _;
    }

    // to remove
    function updateMessenger(address _messenger) external {
        ovmL2CrossDomainMessenger = IMessenger(_messenger);
    }

    function forceClose(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) external onlyL1Contract {
        _forceClose(channelId, owner1, owner2, amount1, amount2);
    }
}