// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// L2LockTime < (L1LockTime + challengeTime) < releaseTime
contract IChannel {
    struct MetaData {
        address owner1;
        uint64 L1LockTime;
        uint32 challengeTime;
        address owner2;
        uint64 L2LockTime;
        IERC20 token1;
        uint64 releaseTime;
        IERC20 token2;
        uint32 chainId1;
        uint32 chainId2;
        uint8 status;
        uint128 amountC1U1;
        uint128 amountC1U2;
        uint128 amountC2U1;
        uint128 amountC2U2;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}