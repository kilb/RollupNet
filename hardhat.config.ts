import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";
dotenvConfig({ path: resolve(__dirname, "./.env") });

import { HardhatUserConfig } from "hardhat/types";

import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";


const chainIds = {
  hardhat: 31337,
  localhost: 1337,
};

const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const MNEMONIC = "work man father plunge mystery proud hollow address reunion sauce theory bonus";

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  defaultNetwork: "localhost",
  networks: {
    localhost: {
      accounts: {
        mnemonic: MNEMONIC,
      },
      chainId: chainIds.localhost,
      url: "http://127.0.0.1:8545"
    },
  },
  solidity: {
    compilers: [
      {
        version: '0.8.17',
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
    ],
  },
  // paths: {
  //   sources: "./contracts",
  //   cache: "./cache",
  //   artifacts: "./artifacts"
  // },
};

export default config;
