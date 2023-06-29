// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IChannel.sol";

// TODO: 如果用户用V(n-1)发起了L1挑战，则另一个用户可以在临近挑战期结束时在L2上发起Vn的close交易（或抢占L1->L2交易），这时应该怎么办？
// 用户仅能在L2LockTime之后发起挑战，如果用户能在L2LockTime之前发起挑战，就会存在这样的问题
// L2LockTime由于时间不完全一致，因此发起挑战截止时间应早于L2LockTime

contract L1Manager is AccessControl, IChannel {
    struct Task {
        address caller; // 使用caller的目的是如果2个用户都相应了，那么可以立马释放
        uint32 version;
        uint64 expire;
        uint128 amountC1U1;
        uint128 amountC1U2;
        uint128 amountC2U1;
        uint128 amountC2U2;
    }

    mapping(uint256 => address) public L2Contracts;
    mapping(uint256 => Task) public tasks;
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addL2Contract(uint256 chainId, address L2Contract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(L2Contracts[chainId] == address(0), "already added!");
        L2Contracts[chainId] = L2Contract;
    }

    function forceRedeem(MetaData memory meta, Signature memory sig1, Signature memory sig2) external {
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
        uint256 channelId = uint256(h);

        require(meta.owner1 == ecrecover(h, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owner2 == ecrecover(h, sig2.v, sig2.r, sig2.s), "wrong signature2!");
        require(meta.L1LockTime >= block.timestamp + meta.challengeTime, "time is up!");
        require(meta.L1DisputeTime <= block.timestamp, "not time yet!");
        if (tasks[channelId].version == 0) {
            tasks[channelId] = Task(msg.sender, 0, uint64(block.timestamp) + meta.challengeTime, 
                               meta.amounts[0][0], meta.amounts[0][1], meta.amounts[1][0], meta.amounts[1][1]);
        }
        
    }

}