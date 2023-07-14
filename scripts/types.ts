import * as ethers from "ethers";

export default class MetaData {
    owners: string[];
    tokens: string[];
    chainIds: number[];
    minValues: string[];
    L2LockTime: number;
    releaseTime: number;
    L1DisputeTime: number;
    L1SettleTime: number;
    L1LockTime: number;
    challengeTime: number;
    amountsC1: string[];
    amountsC2: string[];

    constructor(
        owners: string[],
        tokens: string[],
        chainIds: number[],
        minValues: string[],
        L2LockTime: number,
        releaseTime: number,
        L1DisputeTime: number,
        L1SettleTime: number,
        L1LockTime: number,
        challengeTime: number,
        amountsC1: string[],
        amountsC2: string[]
    ) {
        this.owners = owners;
        this.tokens = tokens;
        this.chainIds = chainIds;
        this.minValues = minValues;
        this.L2LockTime = L2LockTime;
        this.releaseTime = releaseTime;
        this.L1DisputeTime = L1DisputeTime;
        this.L1SettleTime = L1SettleTime;
        this.L1LockTime = L1LockTime;
        this.challengeTime = challengeTime;
        this.amountsC1 = amountsC1;
        this.amountsC2 = amountsC2;
    }

    openHash() {
        let raw = ethers.utils.solidityPack(
            [
                "string",
                "address[2]",
                "address[2]",
                "uint64[2]",
                "uint64[2]",
                "uint128[2]",
                "uint128[2]",
                "uint64",
                "uint64",
                "uint64",
                "uint64",
                "uint64",
                "uint64"
            ], 
            [
                "open",
                this.owners,
                this.tokens,
                this.chainIds,
                this.minValues,
                this.amountsC1,
                this.amountsC2,
                this.L1DisputeTime,
                this.L1SettleTime,
                this.L1LockTime,
                this.L2LockTime,
                this.releaseTime,
                this.challengeTime
            ]);
        let h = ethers.utils.keccak256(raw);
        return h;
    }

    async sign(wallet: ethers.Wallet): Promise<ethers.Signature> {
        let h = this.openHash();
        let messageHashBytes = ethers.utils.arrayify(h)
        let flatSig = await wallet.signMessage(messageHashBytes);
        return ethers.utils.splitSignature(flatSig);
    }
}

function openHash(meta: MetaData) {
    let raw = ethers.utils.solidityPack(
        [
            "string",
            "address[2]",
            "address[2]",
            "uint64[2]",
            "uint64[2]",
            "uint128[2]",
            "uint128[2]",
            "uint64",
            "uint64",
            "uint64",
            "uint64",
            "uint64",
            "uint64"
        ], 
        [
            "open",
            meta.owners,
            meta.tokens,
            meta.chainIds,
            meta.minValues,
            meta.amountsC1,
            meta.amountsC2,
            meta.L1DisputeTime,
            meta.L1SettleTime,
            meta.L1LockTime,
            meta.L2LockTime,
            meta.releaseTime,
            meta.challengeTime
        ]);
    let h = ethers.utils.keccak256(raw);
    return h;
}

// let meta: MetaData = {
//     owners: ["0x0555557997258902185572902627555431450621", "0x0555557997258902185572902627555431450621"],
//     tokens: ["0x2b4D61D87015a7E04Aca172c146742961c610D3E", "0x2b4D61D87015a7E04Aca172c146742961c610D3E"],
//     chainIds: [1, 2],
//     minValues: ["0x1", "0x1"],
//     L2LockTime: 600,
//     releaseTime: 7200,
//     L1DisputeTime: 1200,
//     L1SettleTime: 3600,
//     L1LockTime: 5400,
//     challengeTime: 600,
//     amountsC1: ['0x56bc75e2d63100000', '0x0'],
//     amountsC2: ['0x0', '0xad78ebc5ac6200000']
// };

// let h = openHash(meta);

// let h = meta.openHash();
// let sig = meta.sign();

// console.log(h);

