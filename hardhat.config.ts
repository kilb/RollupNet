import { HardhatUserConfig } from "hardhat/config";

import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";

import "@matterlabs/hardhat-zksync-verify";

import "@nomiclabs/hardhat-ethers";
// import "@nomiclabs/hardhat-etherscan";

// load env file
import dotenv from "dotenv";
dotenv.config();


const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

// dynamically changes endpoints for local tests
const zkSyncTestnet = {
  url: "https://zksync2-testnet.zksync.dev",
  ethNetwork: "goerli",
  zksync: true,
  // contract verification endpoint
  verifyURL:
    "https://zksync2-testnet-explorer.zksync.dev/contract_verification",
};

const config: HardhatUserConfig = {
  zksolc: {
    version: "latest",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200000,
      },
    },
  },
  defaultNetwork: "zkSyncTestnet",
  networks: {
    hardhat: {
      zksync: false,
    },
    zkSyncTestnet,
    Goerli: {
      accounts: [PRIVATE_KEY],
      chainId: 5,
      url: "https://rpc.ankr.com/eth_goerli",
      zksync: false,
    },
    Arbitrum: {
      accounts: [PRIVATE_KEY],
      chainId: 421613,
      url: "https://goerli-rollup.arbitrum.io/rpc",
      zksync: false,
    },
    Optimism: {
      accounts: [PRIVATE_KEY],
      chainId: 420,
      url: "https://goerli.optimism.io",
      zksync: false,
    },
    zkEVM: {
      accounts: [PRIVATE_KEY],
      chainId: 1442,
      url: "https://rpc.public.zkevm-test.net",
      zksync: false,
    },
    Metis: {
      accounts: [PRIVATE_KEY],
      chainId: 599,
      url: "https://goerli.gateway.metisdevops.link",
      zksync: false,
    },
    Scroll: {
      accounts: [PRIVATE_KEY],
      chainId: 534353,
      url: "https://alpha-rpc.scroll.io/l2",
      zksync: false,
    },

  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200000,
      },
      metadata: {
        // do not include the metadata hash, since this is machine dependent
        // and we want all generated code to be deterministic
        // https://docs.soliditylang.org/en/v0.7.6/metadata.html
        bytecodeHash: 'none',
      },
    }
  },
};

export default config;
