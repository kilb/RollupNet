// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Channel.sol";

contract L2Channel is Channel {
    uint256 chainId;

    mapping(uint256 => MetaData) public metas;

    constructor(uint256 _id) {
        chainId = _id;
    }

    // channel id有hash计算得到，避免了碰撞，也避免了伪造
    function open(MetaData memory meta, Signature memory sig1, Signature memory sig2) external {       
        bytes32 h = openHash(meta);
        uint256 channelId = uint256(h);
        require(meta.chainId1 == chainId || meta.chainId2 == chainId, "wrong chainId");
        require(metas[channelId].owner1 == address(0), "already exist!");

        require(meta.owner1 == ecrecover(h, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owner2 == ecrecover(h, sig2.v, sig2.r, sig2.s), "wrong signature2!");

        if (meta.chainId1 == chainId) {
            meta.token1.transferFrom(meta.owner1, address(this), meta.amounts[0][0]);
            meta.token1.transferFrom(meta.owner2, address(this), meta.amounts[0][1]);
        } else {
            meta.token2.transferFrom(meta.owner1, address(this), meta.amounts[1][0]);
            meta.token2.transferFrom(meta.owner2, address(this), meta.amounts[1][1]);
        }
        meta.status = 1;
        metas[channelId] = meta;
    }
    
    // 主动close，需要在l2lockTime之前完成，防止用户临近releaseTime时提交close造成不一致
    // 如果用户临近l2lockTime提交，可能会造成另一条链无法提交，这时用户可以在L1上提交，因此L2LockTime应小于L1LockTime
    function close(uint256 channelId, uint256 amountC1U1, uint256 amountC1U2, uint256 amountC2U1, uint256 amountC2U2, 
                   Signature memory sig1, Signature memory sig2) external {
        MetaData storage mt = metas[channelId];
        bytes32 h = keccak256(abi.encodePacked("close", channelId, amountC1U1, amountC1U2, amountC2U1, amountC2U2));

        require(mt.amounts[0][0] + mt.amounts[0][1] == amountC1U1 + amountC1U2 
                && mt.amounts[1][0] + mt.amounts[1][1] == amountC2U1 + amountC2U2, "wrong amount!");
        require(mt.status == 1, "wrong stage!");
        require(mt.owner1 == ecrecover(h, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(mt.owner2 == ecrecover(h, sig2.v, sig2.r, sig2.s), "wrong signature2!");

        require(mt.L2LockTime >= block.timestamp, "time is up!");

        if(mt.chainId1 == chainId) {
            mt.token1.transfer(mt.owner1, amountC1U1);
            mt.token1.transfer(mt.owner2, amountC1U2);
        } else {
            mt.token2.transfer(mt.owner1, amountC2U1);
            mt.token2.transfer(mt.owner2, amountC2U2);
        }

        mt.status = 2;
    }
    
    // 接收L1指令进行操作，因为L1会进行判断，因此在此处不做太多判断
    function _forceClose(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) internal {
        // require(msg.sender == L1Contract, "Not allowed!");
        MetaData storage mt = metas[channelId];

        require(mt.owner1 == owner1, "Invalid owner1!");
        require(mt.owner2 == owner2, "Invalid owner2!");
        require(mt.status == 1, "wrong stage!");
        if (mt.chainId1 == chainId) {
            require(mt.amounts[0][0] + mt.amounts[0][1] == amount1 + amount2, "wrong amount!");
            mt.token1.transfer(mt.owner1, amount1);
            mt.token1.transfer(mt.owner2, amount2);
        } else {
            require(mt.amounts[1][0] + mt.amounts[1][1] == amount1 + amount2, "wrong amount!");
            mt.token2.transfer(mt.owner1, amount1);
            mt.token2.transfer(mt.owner2, amount2);
        }

        mt.status = 2;
    }
    
    // 超时取回，这样做的目的是如果有用户不合作导致一方账户被锁，那么用户可以不用去L1就可以赎回资产，避免了L1 gas fee消耗
    function redeem(uint256 channelId) external {
        MetaData storage mt = metas[channelId];
        // require(msg.sender == mt.owner1 || msg.sender == mt.owner2, "not allowed!");
        require(mt.status == 1, "wrong stage!");
        require(mt.L2LockTime < block.timestamp, "not time yet!");

        if (mt.chainId1 == chainId) {         
            mt.token1.transfer(mt.owner1, mt.amounts[0][0]);
            mt.token1.transfer(mt.owner2, mt.amounts[0][1]);
        } else {
            mt.token2.transfer(mt.owner1, mt.amounts[1][0]);
            mt.token2.transfer(mt.owner2, mt.amounts[1][1]);
        }

        mt.status = 2;
    }

}


