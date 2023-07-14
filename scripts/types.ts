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
