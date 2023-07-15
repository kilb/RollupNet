import { HardhatUserConfig } from "hardhat/config";
import { zkSyncTestnet, Arbitrum, Scroll, zkEVM, Metis, Optimism, Goerli} from "./networks.config";

import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";

import "@matterlabs/hardhat-zksync-verify";

import "@nomiclabs/hardhat-ethers";
// import "@nomiclabs/hardhat-etherscan";

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
    Goerli,
    Arbitrum,
    Optimism,
    zkEVM,
    Metis,
    Scroll,
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
