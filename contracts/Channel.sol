// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// L2LockTime < L1DisputeTime < (L1SettleTime - challengeTime) < L1SettleTime < L1LockTime < releaseTime
contract Channel {
    struct MetaData {
        address[2] owners;
        IERC20[2] tokens;
        uint64[2] chainIds; // chainId，让layer1合约可以触发正确的layer2合约
        uint128[2] minValues; // 最小传入的msg.value, 为了确保消息能够正确调用
        uint64 L2LockTime; //  Layer2 锁定时间，在L2LockTime之前，用户可以与Layer2合约进行交互（close）
        uint64 releaseTime; // 释放时间，超过releaseTime没有close的channel可以赎回
        uint64 L1DisputeTime; // 可在L1上进行争议解决的最早时间
        uint64 L1SettleTime; // 在L1上争议出结果的最晚时间，即过了该时间后只能重新执行已有的结果
        uint64 L1LockTime; // 可在L1上进行争议解决的最晚时间
        uint64 challengeTime; // L1上用户响应挑战的时间
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
                    meta.owners,
                    meta.tokens,
                    meta.chainIds,
                    meta.minValues,
                    meta.amounts),
                abi.encodePacked(
                    meta.L1DisputeTime,
                    meta.L1SettleTime,
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