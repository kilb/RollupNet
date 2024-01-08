// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./L2Channel.sol";

interface IMessenger {
    function xDomainMessageSender() external returns (address);
}

contract MetisChannel is L2Channel {
    address public L1Contract;
    //testnet & mainnet 0x4200000000000000000000000000000000000007
    IMessenger public ovmL2CrossDomainMessenger;

    constructor(address _l1) L2Channel(1088) {
        L1Contract = _l1;
        ovmL2CrossDomainMessenger = IMessenger(0x4200000000000000000000000000000000000007);
    }

    modifier onlyL1Contract() {
        require(
            msg.sender == address(ovmL2CrossDomainMessenger)
            && ovmL2CrossDomainMessenger.xDomainMessageSender() == L1Contract,
            "Not allowed!"
        );
        _;
    }

     function forceClose(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) external payable onlyL1Contract {
        _forceClose(channelId, owner1, owner2, amount1, amount2);
    }
}