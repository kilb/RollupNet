// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMessenger {
    function xDomainMessageSender() external returns (address);
}

contract OPChannel {
    uint256 chainId = 10;

    address L1Contract;
    IMessenger ovmL2CrossDomainMessenger;

    struct MetaData {
        address owner1;
        uint64 L1LockTime;
        uint32 challengeTime;
        address owner2;
        uint64 L2LockTime;
        IERC20 token1;
        uint32 chainId1;
        uint32 chainId2;
        uint8 status;
        IERC20 token2;
        uint128 amount1;
        uint128 amount2;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(uint256 => MetaData) public metas;

    constructor(address _l1, address _messenger) {
        L1Contract = _l1;
        ovmL2CrossDomainMessenger = IMessenger(_messenger);
    }

    modifier onlyL1Contract() {
        require(
            msg.sender == address(ovmL2CrossDomainMessenger)
            && ovmL2CrossDomainMessenger.xDomainMessageSender() == L1Contract,
            "Not allowed!"
        );
        _;
    }

    function open(MetaData memory meta, Signature memory sig1, Signature memory sig2) external {       
        bytes32 h = keccak256(abi.encodePacked("open", meta.token1, meta.token2, meta.owner1, meta.owner2, 
        meta.amountC1U1, meta.amountC1U2, meta.amountC2U1, meta.amountC2U2, meta.L1LockTime, meta.L2LockTime, meta.challengeTime, meta.chainId1, meta.chainId2));
        uint256 channelId = uint256(h);
        require(meta.chainId1 == chainId || meta.chainId2 == chainId, "wrong chainId");
        require(metas[channelId].owner1 == address(0), "already exist!");

        require(meta.owner1 == ecrecover(h, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owner2 == ecrecover(h, sig2.v, sig2.r, sig2.s), "wrong signature2!");

        meta.token.transferFrom(meta.owner1, address(this), meta.amount1);
        meta.token.transferFrom(meta.owner2, address(this), meta.amount2);
        meta.status = 1;
        metas[channelId] = meta;
    }

    function close(uint256 channelId, uint256 amount1, uint256 amount2, uint256 chainId1, uint256 chainId2,
                   Signature memory sig1, Signature memory sig2) external {
        MetaData storage mt = metas[channelId];
        bytes32 h = keccak256(abi.encodePacked("close", channelId, amount1, amount2, chainId1, chainId2));
        require(mt.L1LockTime > block.timestamp, "not time yet!");

        require(mt.chainId1 == chainId1 && mt.chainId2 == chainId2, "wrong chain id!");
        require(mt.amount1 + mt.amount2 == amount1 + amount2, "wrong amount!");
        require(mt.status == 1, "wrong stage!");
        require(mt.owner1 == ecrecover(h, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(mt.owner2 == ecrecover(h, sig2.v, sig2.r, sig2.s), "wrong signature2!");

        mt.token.transfer(mt.owner1, amount1);
        mt.token.transfer(mt.owner2, amount2);

        mt.status = 2;
    }

    function forceClose(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) external onlyL1Contract {
        // require(msg.sender == L1Contract, "Not allowed!");
        MetaData storage mt = metas[channelId];

        require(mt.owner1 == owner1, "Invalid owner1!");
        require(mt.owner2 == owner2, "Invalid owner2!");

        require(mt.amount1 + mt.amount2 == amount1 + amount2, "wrong amount!");
        require(mt.status == 1, "wrong stage!");

        mt.token.transfer(mt.owner1, amount1);
        mt.token.transfer(mt.owner2, amount2);

        mt.status = 2;
    }

    function redeem(uint256 channelId) external {
        MetaData storage mt = metas[channelId];
        // require(msg.sender == mt.owner1 || msg.sender == mt.owner2, "not allowed!");
        require(mt.status == 1, "wrong stage!");
        require(mt.L2LockTime < block.timestamp, "not time yet!");

        mt.token.transfer(mt.owner1, mt.amount1);
        mt.token.transfer(mt.owner2, mt.amount2);

        mt.status = 2;
    }

}