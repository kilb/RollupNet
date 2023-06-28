// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract L1Manager is AccessControl {
    struct MetaData {
        address owner1;
        uint64 L1LockTime;
        uint32 challengeTime;
        address owner2;
        uint64 L2LockTime;
        IERC20 token;
        uint32 chainId1;
        uint32 chainId2;
        uint8 status;
        uint128 amount1;
        uint128 amount2;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Task {
        address caller;
        uint32 version;
        uint64 expire;
        uint128 amount1;
        uint128 amount2;
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

    function forceRedeem(uint256 channelId, MetaData memory meta, Signature memory sig1, Signature memory sig2) external {
        bytes32 h = keccak256(abi.encodePacked("open", meta.token, meta.owner1, meta.owner2, 
        meta.amount1, meta.amount2, meta.L1LockTime, meta.L2LockTime, meta.challengeTime, meta.chainId1, meta.chainId2));
        uint256 channelId = uint256(h);

        require(meta.owner1 == ecrecover(h, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owner2 == ecrecover(h, sig2.v, sig2.r, sig2.s), "wrong signature2!");
        require(meta.L1LockTime >= block.timestamp + meta.challengeTime, "time is up!");
        if (tasks[channelId].version == 0) {
            tasks[channelId] = Task(msg.sender, 0, block.timestamp + meta.challengeTime, meta.amount1, meta.amount2)
        }
        
    }

}