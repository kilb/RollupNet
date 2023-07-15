
import * as ethers from "ethers";
import { zkSyncTestnet, Arbitrum, Scroll, zkEVM, Metis, Optimism, Goerli} from "../networks.config";
import MetaData from "./types";

import * as L2ChannelArtifact from "../artifacts/contracts/OPChannel.sol/OPChannel.json";
import * as ERC20Artifact from "../artifacts/contracts/TestToken.sol/ABCToken.json";

const L2_CHANNEL_ADDRESS = "0xcAB07BDA4BB67f03236C99768bC67ad4cBaA7a89";
const TEST_TOKEN_ADDRESS = "0x88a5035499978534d0aD672CE717d2009f9B4E66";
const L2_CHANNEL_ADDRESS_ZK = "0xac3089F99dfb8D3B520Bb52F5674Dc28d0928ae1";
const TEST_TOKEN_ADDRESS_ZK = "0x627dD03F977Df2eA5B60bA49210D9de45D351f49";

function prepareMetaWithDefaultSetting(
    owners: string[],
    tokens: string[],
    chainIds: number[],
    amountsC1: string[],
    amountsC2: string[]
): MetaData {
    const meta = new MetaData(
        owners,
        tokens,
        chainIds,
        ['0x38d7ea4c68000', '0x38d7ea4c68000'],
        600, 7200, 1200, 3600, 5400, 600,
        amountsC1,
        amountsC2
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

async function openChannel(
    wallet: ethers.Wallet,
    meta: MetaData,
    sig1: ethers.Signature,
    sig2: ethers.Signature
) {
    // Initialize contract instance
    const contract = new ethers.Contract(
        L2_CHANNEL_ADDRESS,
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
    console.log(`Channel ${meta.openHash()} is opened!`);
}

function getDefaultWallet(id: number, network: string): ethers.Wallet {
    switch(network) {
        case "Optimism": {
            const provider = new ethers.providers.JsonRpcProvider(Optimism.url);
            return new ethers.Wallet(Optimism.accounts[id], provider);
        }
        case "Arbitrum": {
            const provider = new ethers.providers.JsonRpcProvider(Arbitrum.url);
            return new ethers.Wallet(Optimism.accounts[id], provider);
        }
        case "Scroll": {
            const provider = new ethers.providers.JsonRpcProvider(Scroll.url);
            return new ethers.Wallet(Optimism.accounts[id], provider);
        }
        case "zkEVM": {
            const provider = new ethers.providers.JsonRpcProvider(zkEVM.url);
            return new ethers.Wallet(Optimism.accounts[id], provider);
        }
        case "Metis": {
            const provider = new ethers.providers.JsonRpcProvider(Metis.url);
            return new ethers.Wallet(Optimism.accounts[id], provider);
        }
        case "Goerli": {
            const provider = new ethers.providers.JsonRpcProvider(Goerli.url);
            return new ethers.Wallet(Optimism.accounts[id], provider);
        }
    }
    const provider = new ethers.providers.JsonRpcProvider(zkSyncTestnet.url);
    return new ethers.Wallet(Optimism.accounts[id], provider);
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
    // zkSync
    const zksyncWallet1 = getDefaultWallet(1, "zkSync");
    const zksyncWallet2 = getDefaultWallet(2, "zkSync");
    approve(zksyncWallet1, TEST_TOKEN_ADDRESS_ZK, L2_CHANNEL_ADDRESS_ZK);
    approve(zksyncWallet2, TEST_TOKEN_ADDRESS_ZK, L2_CHANNEL_ADDRESS_ZK);
}

approveAll()