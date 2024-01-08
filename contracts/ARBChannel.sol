// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./L2Channel.sol";

contract ARBChannel is L2Channel {
    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);
    address public L1Contract;

    constructor(address _l1) L2Channel(42161) {
        L1Contract = _l1;
    }

    modifier onlyL1Contract() {
        require(undoL1ToL2Alias(msg.sender) == L1Contract, "ONLY_COUNTERPART_CONTRACT");
        _;
    }

     function forceClose(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) external payable onlyL1Contract {
        _forceClose(channelId, owner1, owner2, amount1, amount2);
    }

    /// @notice Utility function converts the address that submitted a tx
    /// to the inbox on L1 to the msg.sender viewed on L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + offset);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed on L2 to the
    /// address that submitted a tx to the inbox on L1
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - offset);
        }
    }
}


