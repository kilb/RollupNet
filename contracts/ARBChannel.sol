// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IChannel.sol";

contract ARBChannel is IChannel {
    uint256 chainId = 42161;

    address L1Contract;

    mapping(uint256 => MetaData) public metas;

    constructor(address _l1) {
        L1Contract = _l1;
    }

    modifier onlyL1Contract() {
        require(undoL1ToL2Alias(msg.sender) == L1Contract, "ONLY_COUNTERPART_CONTRACT");
        _;
    }

    function open(MetaData memory meta, Signature memory sig1, Signature memory sig2) external {       
        bytes32 h = keccak256(abi.encodePacked("open", meta.owner1, meta.owner2, meta.chainId1, meta.chainId2, meta.token1, meta.token2, 
        meta.amountC1U1, meta.amountC1U2, meta.amountC2U1, meta.amountC2U2, meta.L1LockTime, meta.L2LockTime, meta.releaseTime, meta.challengeTime));
        uint256 channelId = uint256(h);
        require(meta.chainId1 == chainId || meta.chainId2 == chainId, "wrong chainId");
        require(metas[channelId].owner1 == address(0), "already exist!");

        require(meta.owner1 == ecrecover(h, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owner2 == ecrecover(h, sig2.v, sig2.r, sig2.s), "wrong signature2!");

        if (meta.chainId1 == chainId) {
            meta.token1.transferFrom(meta.owner1, address(this), meta.amountC1U1);
            meta.token1.transferFrom(meta.owner2, address(this), meta.amountC1U2);
        } else {
            meta.token2.transferFrom(meta.owner1, address(this), meta.amountC2U1);
            meta.token2.transferFrom(meta.owner2, address(this), meta.amountC2U2);
        }
        meta.status = 1;
        metas[channelId] = meta;
    }

    function close(uint256 channelId, uint256 amountC1U1, uint256 amountC1U2, uint256 amountC2U1, uint256 amountC2U2, 
                   Signature memory sig1, Signature memory sig2) external {
        MetaData storage mt = metas[channelId];
        bytes32 h = keccak256(abi.encodePacked("close", channelId, amountC1U1, amountC1U2, amountC2U1, amountC2U2, mt.chainId1, mt.chainId2));

        require(mt.amountC1U1 + mt.amountC1U2 == amountC1U1 + amountC1U2 
                && mt.amountC2U1 + mt.amountC2U2 == amountC2U1 + amountC2U2, "wrong amount!");
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

    function forceClose(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) external onlyL1Contract {
        // require(msg.sender == L1Contract, "Not allowed!");
        MetaData storage mt = metas[channelId];

        require(mt.owner1 == owner1, "Invalid owner1!");
        require(mt.owner2 == owner2, "Invalid owner2!");
        require(mt.status == 1, "wrong stage!");
        if (mt.chainId1 == chainId) {
            require(mt.amountC1U1 + mt.amountC1U2 == amount1 + amount2, "wrong amount!");
            mt.token1.transfer(mt.owner1, amount1);
            mt.token1.transfer(mt.owner2, amount2);
        } else {
            require(mt.amountC2U1 + mt.amountC2U2 == amount1 + amount2, "wrong amount!");
            mt.token2.transfer(mt.owner1, amount1);
            mt.token2.transfer(mt.owner2, amount2);
        }

        mt.status = 2;
    }

    function redeem(uint256 channelId) external {
        MetaData storage mt = metas[channelId];
        // require(msg.sender == mt.owner1 || msg.sender == mt.owner2, "not allowed!");
        require(mt.status == 1, "wrong stage!");
        require(mt.L2LockTime < block.timestamp, "not time yet!");

        if (mt.chainId1 == chainId) {         
            mt.token1.transfer(mt.owner1, mt.amountC1U1);
            mt.token1.transfer(mt.owner2, mt.amountC1U2);
        } else {
            mt.token2.transfer(mt.owner1, mt.amountC2U1);
            mt.token2.transfer(mt.owner2, mt.amountC2U2);
        }

        mt.status = 2;
    }

    function undoL1ToL2Alias(address L1_Contract_Address) public pure returns (address) {
        return address(uint160(L1_Contract_Address) + uint160(0x1111000000000000000000000000000000001111));
    }

}


