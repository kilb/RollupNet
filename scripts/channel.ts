
import { Provider } from "zksync-web3";
import * as ethers from "ethers";
import { zkSyncTestnet, Arbitrum, Scroll, zkEVM, Metis, Optimism, Goerli, Mantle} from "../networks.config";
import MetaData from "./types";

import * as L1ManagerArtifact from "../artifacts/contracts/L1Manager.sol/L1Manager.json";
import * as L2ChannelArtifact from "../artifacts/contracts/OPChannel.sol/OPChannel.json";
import * as ERC20Artifact from "../artifacts/contracts/TestToken.sol/ABCToken.json";

const L1_MANAGER_ADDRESS = "0x88736e6d0Cb9C016A916e0D5827dCBD6BAF1c192";
const L2_CHANNEL_ADDRESS = "0xc840C4ef73f869F6ddA0b6334AF6AB7F2bF03c11";
const TEST_TOKEN_ADDRESS = "0x88a5035499978534d0aD672CE717d2009f9B4E66";
const L2_CHANNEL_ADDRESS_ZK = "0x4351B047eE64c063baC4351A4ed640433d29568d";
const TEST_TOKEN_ADDRESS_ZK = "0x627dD03F977Df2eA5B60bA49210D9de45D351f49";

function delay(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}
 
function prepareMetaData(
    owners: string[],
    tokens: string[],
    chainIds: number[],
    amounts: string[],
    times?: number[],
    startTime?: number
): MetaData {
    if (typeof startTime == 'undefined') {
        startTime = Date.now() / 1000 | 0;
    }
    if (typeof times == 'undefined') {
        times = [600, 7200, 1200, 3600, 5400, 600];
    }
    const meta = new MetaData(
        owners,
        tokens,
        chainIds,
        ['0x38d7ea4c68000', '0x38d7ea4c68000'],
        startTime + times[0], startTime + times[1], startTime + times[2], 
        startTime + times[3], startTime + times[4], times[5],
        amounts,
      );
    return meta;
}

async function approve(
    wallet: ethers.Wallet,
    tokenAddress: string,
    spender: string
) {
    const contract = new ethers.Contract(
        tokenAddress,
        ERC20Artifact.abi,
        wallet
    );

    const tx = await contract.approve(spender, '0xc9f2c9cd04674edea40000000');
    console.log(`[${await wallet.getChainId()}] Transaction to approve ${spender} is ${tx.hash}, sent by ${wallet.address}`);
    await tx.wait();
    console.log(`${tokenAddress} is approved!`);
}

async function transfer2(
    wallet: ethers.Wallet,
    tokenAddress: string,
    spender1: string,
    spender2: string,
    amount: string
) {
    const contract = new ethers.Contract(
        tokenAddress,
        ERC20Artifact.abi,
        wallet
    );
    const tx1 = await contract.transfer(spender1, amount);
    const tx2 = await contract.transfer(spender2, amount);
    await tx1.wait();
    await tx2.wait();
    console.log(`[${await wallet.getChainId()}] Transfer: ${tx1.hash}, ${tx2.hash}`);
}

async function openChannel(
    wallet: ethers.Wallet,
    meta: MetaData,
    sig1: ethers.Signature,
    sig2: ethers.Signature
) {
    const chainId = await wallet.getChainId();
    const channelAddress = chainId == zkSyncTestnet.chainId? L2_CHANNEL_ADDRESS_ZK : L2_CHANNEL_ADDRESS;
    // Initialize contract instance
    const contract = new ethers.Contract(
        channelAddress,
        L2ChannelArtifact.abi,
        wallet
    );

    const tx = await contract.open(
        meta,
        {v: sig1.v, r: sig1.r, s: sig1.s},
        {v: sig2.v, r: sig2.r, s: sig2.s}
    );
    console.log(`[${await wallet.getChainId()}] Transaction to open channel is ${tx.hash}, sent by ${wallet.address}`);
    await tx.wait();
    console.log(`Channel ${meta.metaHash()} is opened!`);
}

async function closeChannel(
    wallet: ethers.Wallet,
    meta: MetaData,
    amounts: string[],
    sig1: ethers.Signature,
    sig2: ethers.Signature
) {
    const chainId = await wallet.getChainId();
    const channelAddress = chainId == zkSyncTestnet.chainId? L2_CHANNEL_ADDRESS_ZK : L2_CHANNEL_ADDRESS;
    // Initialize contract instance
    const contract = new ethers.Contract(
        channelAddress,
        L2ChannelArtifact.abi,
        wallet
    );
    
    const tx = await contract.close(
        meta,
        amounts,
        {v: sig1.v, r: sig1.r, s: sig1.s},
        {v: sig2.v, r: sig2.r, s: sig2.s}
    );
    console.log(`[${await wallet.getChainId()}] Transaction to close channel is ${tx.hash}, sent by ${wallet.address}`);
    await tx.wait();
    console.log(`Channel ${meta.metaHash()} is closed!`);
}

async function forceRedeem(
    wallet: ethers.Wallet,
    meta: MetaData,
    sig1: ethers.Signature,
    sig2: ethers.Signature
) {
    // Initialize contract instance
    const contract = new ethers.Contract(
        L1_MANAGER_ADDRESS,
        L1ManagerArtifact.abi,
        wallet
    );
    
    const tx = await contract.forceRedeem(
        meta,
        {v: sig1.v, r: sig1.r, s: sig1.s},
        {v: sig2.v, r: sig2.r, s: sig2.s}
    );
    console.log(`[L1] ForceRedeem ${tx.hash}, sent by ${wallet.address}`);
    await tx.wait();
    console.log(`Channel ${meta.metaHash()} is ForceRedeemed!`);
}

async function agreeRedeem(
    wallet: ethers.Wallet,
    value1: string,
    meta: MetaData,
    sig1: ethers.Signature,
    sig2: ethers.Signature,
    value2: string = "0x71afd498d0000"
) {
    // Initialize contract instance
    const contract = new ethers.Contract(
        L1_MANAGER_ADDRESS,
        L1ManagerArtifact.abi,
        wallet
    );
    
    const tx = await contract.agreeRedeem(
        value1,
        meta,
        {v: sig1.v, r: sig1.r, s: sig1.s},
        {v: sig2.v, r: sig2.r, s: sig2.s},
        { value: ethers.utils.parseUnits ("2000000", "gwei") }
    );
    console.log(`[L1] AgreeRedeem: ${tx.hash}, sent by ${wallet.address}`);
    await tx.wait();
    console.log(`Channel ${meta.metaHash()}'s redeem is agreed!`);
}

function getDefaultWallet(id: number, network: string): ethers.Wallet {
    switch(network) {
        case "Optimism": {
            const provider = new ethers.providers.JsonRpcProvider(Optimism.url);
            return new ethers.Wallet(Optimism.accounts[id], provider);
        }
        case "Arbitrum": {
            const provider = new ethers.providers.JsonRpcProvider(Arbitrum.url);
            return new ethers.Wallet(Arbitrum.accounts[id], provider);
        }
        case "Scroll": {
            const provider = new ethers.providers.JsonRpcProvider(Scroll.url);
            return new ethers.Wallet(Scroll.accounts[id], provider);
        }
        case "zkEVM": {
            const provider = new ethers.providers.JsonRpcProvider(zkEVM.url);
            return new ethers.Wallet(zkEVM.accounts[id], provider);
        }
        case "Metis": {
            const provider = new ethers.providers.JsonRpcProvider(Metis.url);
            return new ethers.Wallet(Metis.accounts[id], provider);
        }
        case "Goerli": {
            const provider = new ethers.providers.JsonRpcProvider(Goerli.url);
            return new ethers.Wallet(Goerli.accounts[id], provider);
        }
        case "Mantle": {
            const provider = new ethers.providers.JsonRpcProvider(Mantle.url);
            return new ethers.Wallet(Mantle.accounts[id], provider);
        }
    }

    const provider = new Provider(zkSyncTestnet.url);
    return new ethers.Wallet(zkSyncTestnet.accounts[id], provider);
}

async function setL2Contract(chainId: number, address: string) {
    const wallet1 = getDefaultWallet(0, "Goerli");
    // Initialize contract instance
    const contract = new ethers.Contract(
        L1_MANAGER_ADDRESS,
        L1ManagerArtifact.abi,
        wallet1
    );
    
    const tx = await contract.addL2Contract(chainId, address);
    console.log(`[L1] setL2Contract: ${tx.hash}, sent by ${wallet1.address}`);
    await tx.wait();
    console.log(`Chain ${chainId} is added!`);
}

async function transferAll() {
    // const scrollWallet = getDefaultWallet(0, "Scroll");
    // const scrollWallet1 = getDefaultWallet(1, "Scroll");
    // const scrollWallet2 = getDefaultWallet(2, "Scroll");
    // transfer2(scrollWallet, TEST_TOKEN_ADDRESS, scrollWallet1.address, scrollWallet2.address, "0x2a5a058fc295ed000000");
    // const arbWallet = getDefaultWallet(0, "Arbitrum");
    // const arbWallet1 = getDefaultWallet(1, "Arbitrum");
    // const arbWallet2 = getDefaultWallet(2, "Arbitrum");
    // transfer2(arbWallet, TEST_TOKEN_ADDRESS, arbWallet1.address, arbWallet2.address, "0x2a5a058fc295ed000000");
    // const opWallet = getDefaultWallet(0, "Optimism");
    // const opWallet1 = getDefaultWallet(1, "Optimism");
    // const opWallet2 = getDefaultWallet(2, "Optimism");
    // transfer2(opWallet, TEST_TOKEN_ADDRESS, opWallet1.address, opWallet2.address, "0x2a5a058fc295ed000000");
    const zkEVMWallet = getDefaultWallet(0, "zkEVM");
    const zkEVMWallet1 = getDefaultWallet(1, "zkEVM");
    const zkEVMWallet2 = getDefaultWallet(2, "zkEVM");
    transfer2(zkEVMWallet, TEST_TOKEN_ADDRESS, zkEVMWallet1.address, zkEVMWallet2.address, "0x2a5a058fc295ed000000");
    const metisWallet = getDefaultWallet(0, "Metis");
    const metisWallet1 = getDefaultWallet(1, "Metis");
    const metisWallet2 = getDefaultWallet(2, "Metis");
    transfer2(metisWallet, TEST_TOKEN_ADDRESS, metisWallet1.address, metisWallet2.address, "0x2a5a058fc295ed000000");
    const mantleWallet = getDefaultWallet(0, "Mantle");
    const mantleWallet1 = getDefaultWallet(1, "Mantle");
    const mantleWallet2 = getDefaultWallet(2, "Mantle");
    transfer2(mantleWallet, TEST_TOKEN_ADDRESS, mantleWallet1.address, mantleWallet2.address, "0x2a5a058fc295ed000000");
    const zksyncWallet = getDefaultWallet(0, "zkSync");
    const zksyncWallet1 = getDefaultWallet(1, "zkSync");
    const zksyncWallet2 = getDefaultWallet(2, "zkSync");
    transfer2(zksyncWallet, TEST_TOKEN_ADDRESS, zksyncWallet1.address, zksyncWallet2.address, "0x2a5a058fc295ed000000");

}

function approveAll() {
    // Optimism
    const opWallet1 = getDefaultWallet(1, "Optimism");
    const opWallet2 = getDefaultWallet(2, "Optimism");
    approve(opWallet1, TEST_TOKEN_ADDRESS, L2_CHANNEL_ADDRESS);
    approve(opWallet2, TEST_TOKEN_ADDRESS, L2_CHANNEL_ADDRESS);
    // Arbitrum
    const arbWallet1 = getDefaultWallet(1, "Arbitrum");
    const arbWallet2 = getDefaultWallet(2, "Arbitrum");
    approve(arbWallet1, TEST_TOKEN_ADDRESS, L2_CHANNEL_ADDRESS);
    approve(arbWallet2, TEST_TOKEN_ADDRESS, L2_CHANNEL_ADDRESS);
    // Scroll
    const scrollWallet1 = getDefaultWallet(1, "Scroll");
    const scrollWallet2 = getDefaultWallet(2, "Scroll");
    approve(scrollWallet1, TEST_TOKEN_ADDRESS, L2_CHANNEL_ADDRESS);
    approve(scrollWallet2, TEST_TOKEN_ADDRESS, L2_CHANNEL_ADDRESS);
    // zkEVM
    const zkEVMWallet1 = getDefaultWallet(1, "zkEVM");
    const zkEVMWallet2 = getDefaultWallet(2, "zkEVM");
    approve(zkEVMWallet1, TEST_TOKEN_ADDRESS, L2_CHANNEL_ADDRESS);
    approve(zkEVMWallet2, TEST_TOKEN_ADDRESS, L2_CHANNEL_ADDRESS);
    // Metis
    const metisWallet1 = getDefaultWallet(1, "Metis");
    const metisWallet2 = getDefaultWallet(2, "Metis");
    approve(metisWallet1, TEST_TOKEN_ADDRESS, L2_CHANNEL_ADDRESS);
    approve(metisWallet2, TEST_TOKEN_ADDRESS, L2_CHANNEL_ADDRESS);
    // Mantle
    const mantleWallet1 = getDefaultWallet(1, "Mantle");
    const mantleWallet2 = getDefaultWallet(2, "Mantle");
    approve(mantleWallet1, TEST_TOKEN_ADDRESS, L2_CHANNEL_ADDRESS);
    approve(mantleWallet2, TEST_TOKEN_ADDRESS, L2_CHANNEL_ADDRESS);
    // zkSync
    const zksyncWallet1 = getDefaultWallet(1, "zkSync");
    const zksyncWallet2 = getDefaultWallet(2, "zkSync");
    approve(zksyncWallet1, TEST_TOKEN_ADDRESS_ZK, L2_CHANNEL_ADDRESS_ZK);
    approve(zksyncWallet2, TEST_TOKEN_ADDRESS_ZK, L2_CHANNEL_ADDRESS_ZK);
}

async function test1(networks: string[], chainIds: number[]) {
    const wallet1 = getDefaultWallet(1, networks[0]);
    const wallet2 = getDefaultWallet(2, networks[1]);
    const chainId1 = await wallet1.getChainId();
    const token1Address = chainId1 == zkSyncTestnet.chainId? TEST_TOKEN_ADDRESS_ZK : TEST_TOKEN_ADDRESS;
    const chainId2 = await wallet2.getChainId();
    const token2Address = chainId2 == zkSyncTestnet.chainId? TEST_TOKEN_ADDRESS_ZK : TEST_TOKEN_ADDRESS;
    const meta = prepareMetaData(
        [wallet1.address, wallet2.address],
        [token1Address, token2Address],
        chainIds,
        ['0x3635c9adc5dea00000','0x0','0x0','0x3635c9adc5dea00000']
    );

    console.log(`Channel ID: ${meta.metaHash()}`);

    console.log(`To sign data: [["${meta.owners[0]}","${meta.owners[1]}"],["${meta.tokens[0]}","${meta.tokens[1]}"], [${meta.chainIds}], ["${meta.minValues[0]}","${meta.minValues[1]}"], ${meta.L2LockTime}, ${meta.releaseTime}, ${meta.L1DisputeTime}, ${meta.L1SettleTime}, ${meta.L1LockTime}, ${meta.challengeTime}, ["${meta.amounts[0]}","${meta.amounts[1]}","${meta.amounts[2]}","${meta.amounts[3]}"]]`);
    const sig1 = await meta.signOpen(wallet1);
    const sig2 = await meta.signOpen(wallet2);

    console.log(`sig1: ${sig1.v}, ${sig1.r}, ${sig1.s}`);
    console.log(`sig2: ${sig2.v}, ${sig2.r}, ${sig2.s}`);

    // open channel on Optimism
    await openChannel(wallet1, meta, sig1, sig2);
    // open channel on Arbitrum
    await openChannel(wallet2, meta, sig1, sig2);

    // close channel
    const closeSig1 = await meta.signClose(
        wallet1, 
        ['0x0','0x3635c9adc5dea00000','0x3635c9adc5dea00000','0x0']
    );
    const closeSig2 = await meta.signClose(
        wallet2, 
        ['0x0','0x3635c9adc5dea00000','0x3635c9adc5dea00000','0x0']
    );

    console.log(`closeSig1: ${closeSig1.v}, ${closeSig1.r}, ${closeSig1.s}`);
    console.log(`closeSig2: ${closeSig2.v}, ${closeSig2.r}, ${closeSig2.s}`);

    // close on Optimism
    await closeChannel(
        wallet1, meta, 
        ['0x0','0x3635c9adc5dea00000','0x3635c9adc5dea00000','0x0'],
        closeSig1, closeSig2
    );
    // close on Arbitrum
    await closeChannel(
        wallet2, meta, 
        ['0x0','0x3635c9adc5dea00000','0x3635c9adc5dea00000','0x0'],
        closeSig1, closeSig2
    );
}

async function test2(networks: string[], chainIds: number[]) {
    const wallet1 = getDefaultWallet(1, networks[0]);
    const wallet2 = getDefaultWallet(2, networks[1]);
    const l1wallet1 = getDefaultWallet(1, "Goerli");
    const l1wallet2 = getDefaultWallet(2, "Goerli");
    const chainId1 = await wallet1.getChainId();
    const token1Address = chainId1 == zkSyncTestnet.chainId? TEST_TOKEN_ADDRESS_ZK : TEST_TOKEN_ADDRESS;
    const chainId2 = await wallet2.getChainId();
    const token2Address = chainId2 == zkSyncTestnet.chainId? TEST_TOKEN_ADDRESS_ZK : TEST_TOKEN_ADDRESS;
    const meta = prepareMetaData(
        [wallet1.address, wallet2.address],
        [token1Address, token2Address],
        chainIds,
        ['0x3635c9adc5dea00000','0x0','0x0','0x3635c9adc5dea00000'],
        [60, 7200, 120, 3600, 5400, 600],
    );

    console.log(`Channel ID: ${meta.metaHash()}`);

    console.log(`To sign data: [[${meta.owners}], [${meta.tokens}], [${meta.chainIds}], [${meta.minValues}], ${meta.L2LockTime}, ${meta.releaseTime}, ${meta.L1DisputeTime}, ${meta.L1SettleTime}, ${meta.L1LockTime}, ${meta.challengeTime}, [${meta.amounts}]]`);
    const sig1 = await meta.signOpen(wallet1);
    const sig2 = await meta.signOpen(wallet2);
    // open channel on Optimism
    await openChannel(wallet1, meta, sig1, sig2);
    // open channel on Arbitrum
    await openChannel(wallet2, meta, sig1, sig2);
    // wait
    await delay(200000);
    // force redeem
    await forceRedeem(l1wallet1, meta, sig1, sig2);
    // agree redeem
    await agreeRedeem(l1wallet2, '0x38d7ea4c68000', meta, sig1, sig2);
}

async function setAllL2Contract() {
    // await setL2Contract(10, L2_CHANNEL_ADDRESS);
    // await setL2Contract(42161, L2_CHANNEL_ADDRESS);
    // await setL2Contract(1101, L2_CHANNEL_ADDRESS);
    // await setL2Contract(534352, L2_CHANNEL_ADDRESS);
    // await setL2Contract(1088, L2_CHANNEL_ADDRESS);
    await setL2Contract(5000, L2_CHANNEL_ADDRESS);
    // await setL2Contract(324, L2_CHANNEL_ADDRESS_ZK);
}

// transferAll();
// setAllL2Contract();
// approveAll();
// test1(["Arbitrum", "Optimism"], [42161, 10]);
// test1(["Scroll", "zkEVM"], [534352, 1101]);
// test1(["zkSync", "Metis"], [324, 1088]);
// test2(["Arbitrum", "Optimism"], [42161, 10]);
// test2(["Scroll", "zkEVM"], [534352, 1101]);
// test2(["Metis", "zkSync"], [1088, 324]);
test2(["Mantle", "zkSync"], [5000, 324]);
