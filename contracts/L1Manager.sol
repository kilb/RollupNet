// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Channel.sol";
import "./IMessenger.sol";
import "./zkSyncConfig.sol";

// TODO: 如果用户用V(n-1)发起了L1挑战，则另一个用户可以在临近挑战期结束时在L2上发起Vn的close交易（或抢占L1->L2交易），这时应该怎么办？
// 用户仅能在L2LockTime之后发起挑战，如果用户能在L2LockTime之前发起挑战，就会存在这样的问题
// L2LockTime由于时间不完全一致，因此发起挑战截止时间应早于L2LockTime

// 要避免用户在L1上发起两个交易而导致，触发2个L1->L2而导致不一致

// HashTimeLock 其实也假设了时间波动不会太大，安全性假设与我们的方案区别不大

// 如果因为手续费而执行失败呢？1：允许多次执行；2：判断手续费是否充足

// 想象一种场景，用户在临近结束时提交close，但是可以让一个L2失败，这样可能会造成不一致
// 解决办法：留出一个时间，在这段时间内可以再次提交，比如其他用户再次提交
// 或者把最小msg.valuex写在metadata里

// 如果消息转发失败了咋办？节点不转发消息
// 可以证明节点没有转发消息：在L2上声明收不到消息，对手可以去L1上给L2发消息，如果真收不到，则进入异常处理：
// 异常处理：1）增加锁定时间直至消息服务恢复，2）是否可以解锁资产？

contract L1Manager is Ownable, Channel {
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

    mapping(uint256 => uint256) public L2Contracts;
    mapping(uint256 => Task) public tasks;
    
    uint256 gasLimit = 1000000;
    // testnet 0x5086d1eEF304eb5284A0f6720f79403b4e9bE294 1min
    IOPMessenger opMessenger;
    // testnet 0x6BEbC4925716945D46F0Ec336D5C2564F419682C 15min 0gas
    IArbMessenger arbMessenger;
    // testnet  0x1908e2BF4a88F91E4eF0DC72f02b8Ea36BEa2319 15min
    IZKMessenger zkMessenger;
    // mainnet: 0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe
    // testnet: 0xF6BEEeBB578e214CA9E23B0e9683454Ff88Ed2A7 15min
    IPolyMessenger polyMessenger;
    // testnet: 0xe5E30E7c24e4dFcb281A682562E53154C15D3332
    // https://guide.scroll.io/developer-guides/greeting-contract-with-cross-chain-interaction
    IScrollMessenger scrollMessenger;
    // nop
    IStarknetMessenger startnetMessenger;
    // 0x914Aed79Cd083B5043C75A90616CC2A0477bf86c
    IMetisMessenger metisMessenger;
    // testnet: 0x7Bfe603647d5380ED3909F6f87580D0Af1B228B4
    IMantleMessenger mantleMessenger;
    
    constructor() {
        opMessenger = IOPMessenger(0x5086d1eEF304eb5284A0f6720f79403b4e9bE294);
        arbMessenger = IArbMessenger(0x6BEbC4925716945D46F0Ec336D5C2564F419682C);
        zkMessenger = IZKMessenger(0x1908e2BF4a88F91E4eF0DC72f02b8Ea36BEa2319);
        polyMessenger = IPolyMessenger(0xF6BEEeBB578e214CA9E23B0e9683454Ff88Ed2A7);
        scrollMessenger = IScrollMessenger(0x5260e38080BFe97e6C4925d9209eCc5f964373b6);
        metisMessenger = IMetisMessenger(0x914Aed79Cd083B5043C75A90616CC2A0477bf86c);
        mantleMessenger = IMantleMessenger(0x7Bfe603647d5380ED3909F6f87580D0Af1B228B4);
    }

    // for tests
    function setL1Contract(address _opMessenger, address _arbMessenger, address _zkMessenger, address _polyMessenger,
                           address _scrollMessenger, address _metisMessenger) external onlyOwner {
        opMessenger = IOPMessenger(_opMessenger);
        arbMessenger = IArbMessenger(_arbMessenger);
        zkMessenger = IZKMessenger(_zkMessenger);
        polyMessenger = IPolyMessenger(_polyMessenger);
        scrollMessenger = IScrollMessenger(_scrollMessenger);
        metisMessenger = IMetisMessenger(_metisMessenger);
    }

    function addL2Contract(uint256 chainId, uint256 L2Contract) external onlyOwner {
        // require(L2Contracts[chainId] == address(0), "already added!");
        L2Contracts[chainId] = L2Contract;
    }
    
    //claim时间也要<L1SetttleTime, 因此发起者应该把claim时间考虑在内
    function forceRedeem(MetaData memory meta, Signature memory sig1, Signature memory sig2) external {
        bytes32 h = metaHash(meta);
        bytes32 sigMsg = openSigMsg(h);
        uint256 channelId = uint256(h);

        require(meta.owners[0] == ecrecover(sigMsg, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owners[1] == ecrecover(sigMsg, sig2.v, sig2.r, sig2.s), "wrong signature2!");
        require(meta.L1SettleTime >= block.timestamp + meta.challengeTime, "time is up!");
        require(meta.L1DisputeTime <= block.timestamp, "not time yet!");
        if (tasks[channelId].version == 0 && tasks[channelId].status == 0) {
            tasks[channelId] = Task(msg.sender, 1, uint48(block.timestamp + meta.challengeTime), 0, 
                               meta.amounts[0], meta.amounts[1], meta.amounts[2], meta.amounts[3]);
        }
        emit ForceRedeem(channelId, meta);
    }

    //不需要验签
    function agreeRedeem(uint256 value1, MetaData memory meta, Signature memory sig1, Signature memory sig2) external payable {
        require(msg.value > value1, "msg.value is too small");
        bytes32 h = metaHash(meta);
        bytes32 sigMsg = openSigMsg(h);
        uint256 channelId = uint256(h);

        require(meta.owners[0] == ecrecover(sigMsg, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owners[1] == ecrecover(sigMsg, sig2.v, sig2.r, sig2.s), "wrong signature2!");
        require(tasks[channelId].expire >= block.timestamp, "time is up!");
        require(tasks[channelId].version == 1 && tasks[channelId].status == 0, "wrong stage!");
        require((msg.sender == meta.owners[0] && tasks[channelId].caller == meta.owners[1]) 
               ||(msg.sender == meta.owners[1] && tasks[channelId].caller == meta.owners[0]), "wrong caller!");

        tasks[channelId].status = 1;
        //L1 to L2 message
        sendL2Message(value1, meta.chainIds[0], channelId, meta.owners, tasks[channelId].amountC1U1, tasks[channelId].amountC1U2);
        sendL2Message(msg.value - value1, meta.chainIds[1], channelId, meta.owners, tasks[channelId].amountC2U1, tasks[channelId].amountC2U2);
        emit AgreeRedeem(channelId);
    }
    
    // amouts[0] C1U1, amounts[1] C1U2, amounts[2] C2U1, amounts[3] C2U2
    function forceClose(uint256 value1, MetaData memory meta, uint128[4] memory amounts, Signature memory sig1, Signature memory sig2) external payable {
        require(msg.value > value1, "msg.value is too small");
        bytes32 h = metaHash(meta);
        uint256 channelId = uint256(h);
        bytes32 sigMsg = closeSigMsg(h, amounts);
        
        require(meta.owners[0] == ecrecover(sigMsg, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owners[1] == ecrecover(sigMsg, sig2.v, sig2.r, sig2.s), "wrong signature2!");
        require(meta.L1SettleTime >= block.timestamp, "time is up!");
        require(meta.amounts[0] + meta.amounts[1] == amounts[0] + amounts[1], "wrong C1 amount!");
        require(meta.amounts[2] + meta.amounts[3] == amounts[2] + amounts[3], "wrong C2 amount!");
        // require(meta.L1DisputeTime <= block.timestamp, "not time yet!"); 无需该检查，因为L2上只能用Close提前退出
        if (tasks[channelId].status == 0) {
            tasks[channelId] = Task(msg.sender, 0xffffffff, uint48(block.timestamp), 1,
                                    amounts[0], amounts[1], amounts[2], amounts[3]);
            tasks[channelId].status = 1;
            //L1 to L2 message
            sendL2Message(value1, meta.chainIds[0], channelId, meta.owners, tasks[channelId].amountC1U1, tasks[channelId].amountC1U2);
            sendL2Message(msg.value - value1, meta.chainIds[1], channelId, meta.owners, tasks[channelId].amountC2U1, tasks[channelId].amountC2U2);

            emit ForceClose(channelId, amounts[0], amounts[1], amounts[2], amounts[3]);
        }
    }
    
    // challenge 不改变task过期时间，因为不需要来回反复挑战
    function challenge(uint256 value1, MetaData memory meta, uint32 version, uint128[4] memory amounts,
                       Signature memory sig1, Signature memory sig2) external payable {
        require(msg.value > value1, "msg.value is too small");
        bytes32 h = metaHash(meta);
        uint256 channelId = uint256(h);
        bytes32 sigMsg = updateSigMsg(h, version, amounts);
        require(meta.owners[0] == ecrecover(sigMsg, sig1.v, sig1.r, sig1.s), "wrong signature1!");
        require(meta.owners[1] == ecrecover(sigMsg, sig2.v, sig2.r, sig2.s), "wrong signature2!");

        require(tasks[channelId].status == 0 && tasks[channelId].version > 0, "wrong stage!");
        require(tasks[channelId].expire >= block.timestamp, "time is up!");

        require(meta.amounts[0] + meta.amounts[1] == amounts[0] + amounts[1], "wrong C1 amount!");
        require(meta.amounts[2] + meta.amounts[3] == amounts[2] + amounts[3], "wrong C2 amount!");

        if (version > tasks[channelId].version) {
            tasks[channelId].version = uint32(version);
            tasks[channelId].amountC1U1 = amounts[0];
            tasks[channelId].amountC1U2 = amounts[1];
            tasks[channelId].amountC2U1 = amounts[2];
            tasks[channelId].amountC2U2 = amounts[3];
        }

        if ((msg.sender == meta.owners[0] && tasks[channelId].caller == meta.owners[1]) 
           ||(msg.sender == meta.owners[1] && tasks[channelId].caller == meta.owners[0])) {
            tasks[channelId].status = 1;
            //L1 to L2 message
            sendL2Message(value1, meta.chainIds[0], channelId, meta.owners, tasks[channelId].amountC1U1, tasks[channelId].amountC1U2);
            sendL2Message(msg.value - value1, meta.chainIds[1], channelId, meta.owners, tasks[channelId].amountC2U1, tasks[channelId].amountC2U2);
        }

        emit Challenge(channelId, tasks[channelId].status, amounts[0], amounts[1], amounts[2], amounts[3]);
    }

    // 如果时间到期了未挑战，则需claim
    // 如果发送消息未能在L2上成功执行，则需claim
    function claim(uint256 value1, MetaData memory meta) external payable {
        require(msg.value > value1, "msg.value is too small");

        uint256 channelId = uint256(metaHash(meta));
        // require(tasks[channelId].version == 1 && tasks[channelId].status == 0, "wrong stage!");
        require(tasks[channelId].expire < block.timestamp || tasks[channelId].status == 1, "not time!");
        require(block.timestamp < meta.L1LockTime, "time is up");
        tasks[channelId].status = 1;
        //L1 to L2 message
        sendL2Message(value1, meta.chainIds[0], channelId, meta.owners, tasks[channelId].amountC1U1, tasks[channelId].amountC1U2);
        sendL2Message(msg.value - value1, meta.chainIds[1], channelId, meta.owners, tasks[channelId].amountC2U1, tasks[channelId].amountC2U2);
        emit Claim(channelId, tasks[channelId].amountC1U1, tasks[channelId].amountC1U2, tasks[channelId].amountC2U1, tasks[channelId].amountC2U2);
    }

    function sendL2Message(uint256 value, uint256 chainId, uint256 channelId, address[2] memory owners, uint256 amount1, uint256 amount2) private {
        if (chainId == 10) {
            OPL2Message(value, channelId, owners, amount1, amount2);
        } else if (chainId == 42161) {
            ARBL2Message(value, channelId, owners, amount1, amount2);
        } else if (chainId == 324) {
            ZKL2Message(value, channelId, owners, amount1, amount2);
        } else if (chainId == 1101) {
            PolyL2Message(value, channelId, owners, amount1, amount2);
        } else if (chainId == 534352) {
            ScrollL2Message(value, channelId, owners, amount1, amount2);
        } else if (chainId == 5000) {
            MantleL2Message(value, channelId, owners, amount1, amount2);
        }
        
        emit L2MesseageSend(chainId, channelId, owners[0], owners[1], amount1, amount2);
    }
    
    // 0 gas fee
    function OPL2Message(uint256 value, uint256 channelId, address[2] memory owners, uint256 amount1, uint256 amount2) private {
        opMessenger.sendMessage{value: value}(
            address(uint160(L2Contracts[10])),
            abi.encodeWithSignature(
                "forceClose(uint256,address,address,uint256,uint256)",
                channelId,
                owners[0],
                owners[1],
                amount1,
                amount2
            ),
            uint32(gasLimit) // use whatever gas limit you want
        );
    }

    // 0 gas fee
    function MantleL2Message(uint256 value, uint256 channelId, address[2] memory owners, uint256 amount1, uint256 amount2) private {
        mantleMessenger.sendMessage{value: value}(
            address(uint160(L2Contracts[5000])),
            abi.encodeWithSignature(
                "forceClose(uint256,address,address,uint256,uint256)",
                channelId,
                owners[0],
                owners[1],
                amount1,
                amount2
            ),
            uint32(gasLimit) // use whatever gas limit you want
        );
    }
    
    // submit cost + gasPrice * gasLimit <= msg.value
    function ARBL2Message(uint256 value, uint256 channelId, address[2] memory owners, uint256 amount1, uint256 amount2) private {
        arbMessenger.createRetryableTicket{value: value}(
            address(uint160(L2Contracts[42161])),
            0,
            value / 2,
            tx.origin,
            tx.origin,
            gasLimit,
            (value / 2) / gasLimit,
            abi.encodeWithSignature(
                "forceClose(uint256,address,address,uint256,uint256)",
                channelId,
                owners[0],
                owners[1],
                amount1, 
                amount2
            )
        );
    }
    
    // msg.value > L2Gasprice * gasLimit, L2Gasprice 由消息合约计算得到
    function ZKL2Message(uint256 value, uint256 channelId, address[2] memory owners, uint256 amount1, uint256 amount2) private {
        zkMessenger.requestL2Transaction{value: value}(
            address(uint160(L2Contracts[324])),
            0,
            abi.encodeWithSignature(
                "forceClose(uint256,address,address,uint256,uint256)",
                channelId,
                owners[0],
                owners[1],
                amount1,
                amount2
            ),
            gasLimit,
            REQUIRED_L2_GAS_PRICE_PER_PUBDATA,
            new bytes[](0),
            tx.origin
        );
    }

    function PolyL2Message(uint256 value, uint256 channelId, address[2] memory owners, uint256 amount1, uint256 amount2) private {
        polyMessenger.bridgeMessage{value: value}(
            1,
            address(uint160(L2Contracts[1101])),
            true,
            abi.encodeWithSignature(
                "forceClose(uint256,address,address,uint256,uint256)",
                channelId,
                owners[0],
                owners[1],
                amount1,
                amount2
            )
        );
    }

    function ScrollL2Message(uint256 value, uint256 channelId, address[2] memory owners, uint256 amount1, uint256 amount2) private {
        scrollMessenger.sendMessage{value: value}(
            address(uint160(L2Contracts[534352])),
            0,
            abi.encodeWithSignature(
                "forceClose(uint256,address,address,uint256,uint256)",
                channelId,
                owners[0],
                owners[1],
                amount1,
                amount2
            ),
            gasLimit
        );
    }

    function StarknetL2Message(uint256 value, uint256 channelId, address[2] memory owners, uint256 amount1, uint256 amount2) private {
        uint256 selector = 0xdead;
        uint256[] memory payload = new uint256[](5);
        payload[0] = channelId;
        payload[1] = uint256(uint160(owners[0]));
        payload[2] = uint256(uint160(owners[1]));
        payload[3] = amount1;
        payload[4] = amount2;
        // Sending the message
        startnetMessenger.sendMessageToL2{value: value}(L2Contracts[1111], selector, payload);
    }

    function MetisL2Message(uint256 value, uint256 channelId, address[2] memory owners, uint256 amount1, uint256 amount2) private {
        metisMessenger.sendMessage{value: value}(
            address(uint160(L2Contracts[1088])),
            abi.encodeWithSignature(
                "forceClose(uint256,address,address,uint256,uint256)",
                channelId,
                owners[0],
                owners[1],
                amount1,
                amount2
            ),
            uint32(gasLimit) // use whatever gas limit you want
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
