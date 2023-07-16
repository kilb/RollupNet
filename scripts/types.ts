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
    amounts: string[];

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
        amounts: string[],
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
        this.amounts = amounts;
    }

    metaHash() {
        let raw = ethers.utils.solidityPack(
            [
                "string",
                "address[2]",
                "address[2]",
                "uint64[2]",
                "uint64[2]",
                "uint128[4]",
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
                this.amounts,
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

    async signOpen(wallet: ethers.Wallet): Promise<ethers.Signature> {
        let h = this.metaHash();
        let messageHashBytes = ethers.utils.arrayify(h);
        let flatSig = await wallet.signMessage(messageHashBytes);
        return ethers.utils.splitSignature(flatSig);
    }

    async signUpdte(
        wallet: ethers.Wallet,
        version: number,
        amounts: string[]
    ): Promise<ethers.Signature> {
        let h = this.metaHash();
        let raw = ethers.utils.solidityPack([
            "string",
            "uint32",
            "bytes32",
            "uint128[4]"
        ],
        [
            "update",
            version,
            h,
            amounts
        ]);
        let messageHashBytes = ethers.utils.arrayify(raw);
        let flatSig = await wallet.signMessage(messageHashBytes);
        return ethers.utils.splitSignature(flatSig);
    }

    async signClose(
        wallet: ethers.Wallet,
        amounts: string[]
    ): Promise<ethers.Signature> {
        let h = this.metaHash();
        let raw = ethers.utils.solidityPack([
            "string",
            "bytes32",
            "uint128[4]"
        ],
        [
            "close",
            h,
            amounts
        ]);
        let messageHashBytes = ethers.utils.arrayify(raw);
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
            meta.amounts[0],
            meta.amounts[1],
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
