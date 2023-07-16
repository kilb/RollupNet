// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Channel.sol";

contract L2Channel is Channel {
    struct ChannelInfo {
        address token;
        uint8 status; // 0: empty 1: open 2: close
    }
    uint256 public chainId;

    mapping(uint256 => ChannelInfo) public channels; // 0: empty 1: open 2: close

    constructor(uint256 _id) {
        chainId = _id;
    }

    // channel id有hash计算得到，避免了碰撞，也避免了伪造
    function open(MetaData memory meta, Signature memory sig1, Signature memory sig2) external {       
        bytes32 h = metaHash(meta);
        bytes32 sigMsg = openSigMsg(h);
        uint256 channelId = uint256(h);
        require(meta.chainIds[0] == chainId || meta.chainIds[1] == chainId, "wrong chainId");
        require(channels[channelId].status == 0, "already exist!");

        require(meta.owners[0] == ecrecover(sigMsg, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owners[1] == ecrecover(sigMsg, sig2.v, sig2.r, sig2.s), "wrong signature2!");

        if (meta.chainIds[0] == chainId) {
            meta.tokens[0].transferFrom(meta.owners[0], address(this), meta.amounts[0]);
            meta.tokens[0].transferFrom(meta.owners[1], address(this), meta.amounts[1]);
            channels[channelId] = ChannelInfo(address(meta.tokens[0]), 1);
        } else {
            meta.tokens[1].transferFrom(meta.owners[0], address(this), meta.amounts[2]);
            meta.tokens[1].transferFrom(meta.owners[1], address(this), meta.amounts[3]);
            channels[channelId] = ChannelInfo(address(meta.tokens[1]), 1);
        }
        
        emit ChannelOpen(channelId, meta);
    }
    
    // 主动close，需要在l2lockTime之前完成，防止用户临近releaseTime时提交close造成不一致
    // 如果用户临近l2lockTime提交，可能会造成另一条链无法提交，这时用户可以在L1上提交，因此L2LockTime应小于L1LockTime
    function close(MetaData memory meta, uint128[4] memory amounts, 
                   Signature memory sig1, Signature memory sig2) external {
        bytes32 h = metaHash(meta);
        uint256 channelId = uint256(h);
        bytes32 sigMsg = closeSigMsg(h, amounts);

        require(meta.amounts[0] + meta.amounts[1] == amounts[0] + amounts[1] 
                && meta.amounts[2] + meta.amounts[3] == amounts[2] + amounts[3], "wrong amount!");
        require(channels[channelId].status == 1, "wrong stage!");
        require(meta.owners[0] == ecrecover(sigMsg, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owners[1] == ecrecover(sigMsg, sig2.v, sig2.r, sig2.s), "wrong signature2!");

        require(meta.L2LockTime >= block.timestamp, "time is up!");

        if(meta.chainIds[0] == chainId) {
            meta.tokens[0].transfer(meta.owners[0], amounts[0]);
            meta.tokens[0].transfer(meta.owners[1], amounts[1]);
        } else {
            meta.tokens[1].transfer(meta.owners[0], amounts[2]);
            meta.tokens[1].transfer(meta.owners[1], amounts[3]);
        }

        channels[channelId].status = 2;
        emit ChannelClose(channelId, amounts[0], amounts[1], amounts[2], amounts[3]);
    }
    
    // 接收L1指令进行操作，因为L1会进行判断，因此在此处不做太多判断
    function _forceClose(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) internal {
        require(channels[channelId].status == 1, "wrong stage!");
        
        IERC20 token = IERC20(channels[channelId].token);
        token.transfer(owner1, amount1);
        token.transfer(owner2, amount2);

        channels[channelId].status == 2;
    }
    
    // 超时取回，这样做的目的是如果有用户不合作导致一方账户被锁，那么用户可以不用去L1就可以赎回资产，避免了L1 gas fee消耗
    function redeem(MetaData memory meta) external {
        uint256 channelId = uint256(metaHash(meta));
        // require(msg.sender == mt.owner1 || msg.sender == mt.owner2, "not allowed!");
        require(channels[channelId].status == 1, "wrong stage!");
        require(meta.L2LockTime < block.timestamp, "not time yet!");

        if (meta.chainIds[0] == chainId) {         
            meta.tokens[0].transfer(meta.owners[0], meta.amounts[0]);
            meta.tokens[0].transfer(meta.owners[1], meta.amounts[1]);
        } else {
            meta.tokens[1].transfer(meta.owners[0], meta.amounts[2]);
            meta.tokens[1].transfer(meta.owners[1], meta.amounts[3]);
        }

        channels[channelId].status == 2;
        emit ChannelRedeem(channelId);
    }

    event ChannelOpen(uint256 indexed channelId, MetaData meta);
    event ChannelClose(uint256 indexed channelId, uint256 amountC1U1, uint256 amountC1U2, uint256 amountC2U1, uint256 amountC2U2);
    event ChannelRedeem(uint256 indexed channelId);
}
