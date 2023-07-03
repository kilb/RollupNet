// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Channel.sol";
import "./IMessenger.sol";

// TODO: 如果用户用V(n-1)发起了L1挑战，则另一个用户可以在临近挑战期结束时在L2上发起Vn的close交易（或抢占L1->L2交易），这时应该怎么办？
// 用户仅能在L2LockTime之后发起挑战，如果用户能在L2LockTime之前发起挑战，就会存在这样的问题
// L2LockTime由于时间不完全一致，因此发起挑战截止时间应早于L2LockTime

// 要避免用户在L1上发起两个交易而导致，触发2个L1->L2而导致不一致

// HashTimeLock 其实也假设了时间波动不会太大，安全性假设与我们的方案区别不大

contract L1Manager is AccessControl, Channel {
    struct Task {
        address caller; // 使用caller的目的是如果2个用户都相应了，那么可以立马释放
        uint32 version;
        uint48 expire;
        uint16 status; // 0: open, 1: close
        uint128 amountC1U1;
        uint128 amountC1U2;
        uint128 amountC2U1;
        uint128 amountC2U2;
    }

    mapping(uint256 => address) public L2Contracts;
    mapping(uint256 => Task) public tasks;
    
    uint256 gasLimit = 1000000;
    IOPMessenger opMessenger;
    IArbMessenger arbMessenger;
    IZKMessenger zkMessenger;
    // testnet: 0xF6BEEeBB578e214CA9E23B0e9683454Ff88Ed2A7
    IPolyMessenger polyMessenger;
    IScrollMessenger scrollMessenger;
    
    constructor(address _opMessenger, address _arbMessenger) {
        opMessenger = IOPMessenger(_opMessenger);
        arbMessenger = IArbMessenger(_arbMessenger);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addL2Contract(uint256 chainId, address L2Contract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(L2Contracts[chainId] == address(0), "already added!");
        L2Contracts[chainId] = L2Contract;
    }
    
    //claim时间也要<L1LockTime, 因此发起者应该把claim时间考虑在内
    function forceRedeem(MetaData memory meta, Signature memory sig1, Signature memory sig2) external {
        bytes32 h = openHash(meta);
        uint256 channelId = uint256(h);

        require(meta.owner1 == ecrecover(h, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owner2 == ecrecover(h, sig2.v, sig2.r, sig2.s), "wrong signature2!");
        require(meta.L1LockTime >= block.timestamp + meta.challengeTime, "time is up!");
        require(meta.L1DisputeTime <= block.timestamp, "not time yet!");
        if (tasks[channelId].version == 0 && tasks[channelId].status == 0) {
            tasks[channelId] = Task(msg.sender, 1, uint48(block.timestamp) + meta.challengeTime, 0, 
                               meta.amounts[0][0], meta.amounts[0][1], meta.amounts[1][0], meta.amounts[1][1]);
        }
        emit ForceRedeem(channelId, meta);
    }

    function agreeRedeem(MetaData memory meta, Signature memory sig1, Signature memory sig2) external payable {
        bytes32 h = openHash(meta);
        uint256 channelId = uint256(h);

        require(meta.owner1 == ecrecover(h, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owner2 == ecrecover(h, sig2.v, sig2.r, sig2.s), "wrong signature2!");
        require(tasks[channelId].expire >= block.timestamp, "time is up!");
        require(tasks[channelId].version == 1 && tasks[channelId].status == 0, "wrong stage!");
        require((msg.sender == meta.owner1 && tasks[channelId].caller == meta.owner2) 
               ||(msg.sender == meta.owner2 && tasks[channelId].caller == meta.owner1), "wrong caller!");

        tasks[channelId].status = 1;
        //L1 to L2 message
        sendL2Message(meta.chainId1, channelId, meta.owner1, meta.owner2, tasks[channelId].amountC1U1, tasks[channelId].amountC1U2);
        sendL2Message(meta.chainId2, channelId, meta.owner1, meta.owner2, tasks[channelId].amountC2U1, tasks[channelId].amountC2U2);
        emit AgreeRedeem(channelId);
    }

    function forceClose(MetaData memory meta, uint256 amountC1U1, uint256 amountC1U2, uint256 amountC2U1, 
                        uint256 amountC2U2, Signature memory sig1, Signature memory sig2) external payable {
        uint256 channelId = uint256(openHash(meta));

        bytes32 h = keccak256(abi.encodePacked("close", channelId, amountC1U1, amountC1U2, amountC2U1, amountC2U2));
        require(meta.owner1 == ecrecover(h, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owner2 == ecrecover(h, sig2.v, sig2.r, sig2.s), "wrong signature2!");
        require(meta.L1LockTime >= block.timestamp, "time is up!");
        require(meta.amounts[0][0] + meta.amounts[0][1] == amountC1U1 + amountC1U2, "wrong C1 amount!");
        require(meta.amounts[1][0] + meta.amounts[1][1] == amountC2U1 + amountC2U2, "wrong C2 amount!");
        // require(meta.L1DisputeTime <= block.timestamp, "not time yet!"); 无需该检查，因为L2上只能用Close提前退出
        if (tasks[channelId].status == 0) {
            tasks[channelId] = Task(msg.sender, 0xffffffff, uint48(block.timestamp), 1, 
                               uint128(amountC1U1), uint128(amountC1U2), uint128(amountC2U1), uint128(amountC2U2));
            tasks[channelId].status = 1;
            //L1 to L2 message
            sendL2Message(meta.chainId1, channelId, meta.owner1, meta.owner2, tasks[channelId].amountC1U1, tasks[channelId].amountC1U2);
            sendL2Message(meta.chainId2, channelId, meta.owner1, meta.owner2, tasks[channelId].amountC2U1, tasks[channelId].amountC2U2);

            emit ForceClose(channelId, amountC1U1, amountC1U2, amountC2U1, amountC2U2);
        }
    }
    
    // challenge 不改变task过期时间，因为不需要来回反复挑战
    function challenge(MetaData memory meta, uint256 version, uint256 amountC1U1, uint256 amountC1U2, 
                       uint256 amountC2U1, uint256 amountC2U2, Signature memory sig1, Signature memory sig2) external payable {
        uint256 channelId = uint256(openHash(meta));
        bytes32 h = keccak256(abi.encodePacked("update", version, channelId, amountC1U1, amountC1U2, amountC2U1, amountC2U2));
        require(meta.owner1 == ecrecover(h, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owner2 == ecrecover(h, sig2.v, sig2.r, sig2.s), "wrong signature2!");

        require(tasks[channelId].status == 0 && tasks[channelId].version > 0, "wrong stage!");
        require(tasks[channelId].expire >= block.timestamp, "time is up!");

        require(meta.amounts[0][0] + meta.amounts[0][1] == amountC1U1 + amountC1U2, "wrong C1 amount!");
        require(meta.amounts[1][0] + meta.amounts[1][1] == amountC2U1 + amountC2U2, "wrong C2 amount!");

        if (version > tasks[channelId].version) {
            tasks[channelId].version = uint32(version);
            tasks[channelId].amountC1U1 = uint128(amountC1U1);
            tasks[channelId].amountC1U2 = uint128(amountC1U2);
            tasks[channelId].amountC2U1 = uint128(amountC2U1);
            tasks[channelId].amountC2U2 = uint128(amountC2U2);
        }

        if ((msg.sender == meta.owner1 && tasks[channelId].caller == meta.owner2) 
           ||(msg.sender == meta.owner2 && tasks[channelId].caller == meta.owner1)) {
            tasks[channelId].status = 1;
            //L1 to L2 message
            sendL2Message(meta.chainId1, channelId, meta.owner1, meta.owner2, tasks[channelId].amountC1U1, tasks[channelId].amountC1U2);
            sendL2Message(meta.chainId2, channelId, meta.owner1, meta.owner2, tasks[channelId].amountC2U1, tasks[channelId].amountC2U2);
        }

        emit Challenge(channelId, tasks[channelId].status, amountC1U1, amountC1U2, amountC2U1, amountC2U2);
    }

    // 如果时间到期了未挑战，则需claim
    function claim(MetaData memory meta) external payable {
        uint256 channelId = uint256(openHash(meta));
        require(tasks[channelId].version == 1 && tasks[channelId].status == 0, "wrong stage!");
        require(tasks[channelId].expire < block.timestamp, "not time!");
        tasks[channelId].status = 1;
        //L1 to L2 message
        sendL2Message(meta.chainId1, channelId, meta.owner1, meta.owner2, tasks[channelId].amountC1U1, tasks[channelId].amountC1U2);
        sendL2Message(meta.chainId2, channelId, meta.owner1, meta.owner2, tasks[channelId].amountC2U1, tasks[channelId].amountC2U2);
        emit Claim(channelId, tasks[channelId].amountC1U1, tasks[channelId].amountC1U2, tasks[channelId].amountC2U1, tasks[channelId].amountC2U2);
    }

    function sendL2Message(uint256 chainId, uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) private {
        if (chainId == 10) {
            OPL2Message(channelId, owner1, owner2, amount1, amount2);
        } else if (chainId == 42161) {
            ARBL2Message(channelId, owner1, owner2, amount1, amount2);
        } else if (chainId == 324) {
            ZKL2Message(channelId, owner1, owner2, amount1, amount2);
        } else if (chainId == 1101) {
            PolyL2Message(channelId, owner1, owner2, amount1, amount2);
        } else if (chainId == 534352) {
            ScrollL2Message(channelId, owner1, owner2, amount1, amount2);
        }
        
        emit L2MesseageSend(chainId, channelId, owner1, owner2, amount1, amount2);
    }

    function OPL2Message(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) private {
        opMessenger.sendMessage{value: msg.value}(
            L2Contracts[10],
            abi.encodeWithSignature(
                "forceClose(uint256,address,address,uint256,uint256)",
                channelId,
                owner1,
                owner2,
                amount1,
                amount2
            ),
            uint32(gasLimit) // use whatever gas limit you want
        );
    }

    function ARBL2Message(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) private {
        arbMessenger.createRetryableTicket{value: msg.value}(
            L2Contracts[42161],
            msg.value,
            msg.value,
            tx.origin,
            tx.origin,
            gasLimit,
            msg.value / gasLimit - 10,
            abi.encodeWithSignature(
                "forceClose(uint256,address,address,uint256,uint256)",
                channelId,
                owner1,
                owner2,
                amount1,
                amount2
            )
        );
    }

    function ZKL2Message(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) private {
        zkMessenger.requestL2Transaction{value: msg.value}(
            L2Contracts[324],
            0,
            abi.encodeWithSignature(
                "forceClose(uint256,address,address,uint256,uint256)",
                channelId,
                owner1,
                owner2,
                amount1,
                amount2
            ),
            gasLimit,
            msg.value / gasLimit - 10,
            new bytes[](0),
            tx.origin
        );
    }

    function PolyL2Message(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) private {
        polyMessenger.bridgeMessage{value: msg.value}(
            1,
            L2Contracts[1101],
            true,
            abi.encodeWithSignature(
                "forceClose(uint256,address,address,uint256,uint256)",
                channelId,
                owner1,
                owner2,
                amount1,
                amount2
            )
        );
    }

    function ScrollL2Message(uint256 channelId, address owner1, address owner2, uint256 amount1, uint256 amount2) private {
        scrollMessenger.sendMessage{value: msg.value}(
            L2Contracts[534352],
            0,
            abi.encodeWithSignature(
                "forceClose(uint256,address,address,uint256,uint256)",
                channelId,
                owner1,
                owner2,
                amount1,
                amount2
            ),
            gasLimit
        );
    }

    event ForceRedeem(uint256 indexed channelId, MetaData meta);
    event AgreeRedeem(uint256 indexed channelId);
    event ForceClose(
        uint256 indexed channelId, 
        uint256 amountC1U1, 
        uint256 amountC1U2, 
        uint256 amountC2U1, 
        uint256 amountC2U2
    );
    event Challenge(
        uint256 indexed channelId,
        uint256 status, 
        uint256 amountC1U1, 
        uint256 amountC1U2, 
        uint256 amountC2U1, 
        uint256 amountC2U2
    );
    event Claim(
        uint256 indexed channelId,
        uint256 amountC1U1, 
        uint256 amountC1U2, 
        uint256 amountC2U1, 
        uint256 amountC2U2
    );
    event L2MesseageSend(
        uint256 indexed chainId,
        uint256 indexed channelId,
        address owner1, 
        address owner2, 
        uint256 amount1, 
        uint256 amount2
    );
}