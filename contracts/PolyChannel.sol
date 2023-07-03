// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./L2Channel.sol";

contract PolyChannel is L2Channel {
    address public L1Contract;
    // testnet: 0xF6BEEeBB578e214CA9E23B0e9683454Ff88Ed2A7
    // mainnet: 0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe
    // 15min
    // 10min
    address public l2Bridge;

    constructor(address _l1) L2Channel(1101) {
        L1Contract = _l1;
        l2Bridge = 0xF6BEEeBB578e214CA9E23B0e9683454Ff88Ed2A7;
    }

    modifier onlyL1Contract(address caller, uint32 originNetwork) {
        require(
            msg.sender == l2Bridge && caller == L1Contract && originNetwork == 0,
            "Not allowed!"
        );
        _;
    }

    function forceClose(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) public {
        require(msg.sender == address(this), "not allowed!");
        _forceClose(channelId, owner1, owner2, amount1, amount2);
    }

    function onMessageReceived(address originAddress, uint32 originNetwork, bytes memory data) external payable onlyL1Contract(originAddress, originNetwork) {
        (bool success, ) = address(this).call(data);
        if (!success) {
            revert('metadata execution failed');
        }
    }
}