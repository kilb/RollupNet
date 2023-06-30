// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// L2LockTime < L1DisputeTime < (L1LockTime - challengeTime) < L1LockTime < releaseTime
contract Channel {
    struct MetaData {
        address owner1;
        uint48 L2LockTime; //  Layer2 锁定时间，在L2LockTime之前，用户可以与Layer2合约进行交互
        uint48 releaseTime; // 释放时间，超过releaseTime没有close的channel可以赎回
        address owner2;
        uint48 L1DisputeTime; // 可在L1上进行争议解决的最早时间
        uint48 L1LockTime; // 可在L1上进行争议解决的最晚时间
        IERC20 token1;
        uint32 challengeTime; // L1上用户响应挑战的时间
        IERC20 token2;
        uint32 chainId1; // chainId，让layer1合约可以触发正确的layer2合约
        uint32 chainId2;
        uint8 status;
        uint128[2][2] amounts; // 用户金额
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function openHash(MetaData memory meta) internal pure returns (bytes32) {
        bytes32 h = keccak256(
            bytes.concat(
                abi.encodePacked(
                    "open",
                    meta.owner1,
                    meta.owner2,
                    meta.chainId1,
                    meta.chainId2,
                    meta.token1,
                    meta.token2),
                abi.encodePacked(
                    meta.amounts,
                    meta.L1DisputeTime,
                    meta.L1LockTime,
                    meta.L2LockTime,
                    meta.releaseTime,
                    meta.challengeTime
                )
            )
        );
        return h;
    }
}