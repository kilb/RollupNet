// load env file
import dotenv from "dotenv";
dotenv.config();


const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const OP1_PRIVATE_KEY = process.env.OP1_PRIVATE_KEY || "";
const OP2_PRIVATE_KEY = process.env.OP2_PRIVATE_KEY || "";

// dynamically changes endpoints for local tests
export const zkSyncTestnet = {
  accounts: [PRIVATE_KEY, OP1_PRIVATE_KEY, OP2_PRIVATE_KEY],
  url: "https://zksync2-testnet.zksync.dev",
  ethNetwork: "goerli",
  chainId: 280,
  zksync: true,
  // contract verification endpoint
  verifyURL:
    "https://zksync2-testnet-explorer.zksync.dev/contract_verification",
};

export const Goerli = {
  accounts: [PRIVATE_KEY, OP1_PRIVATE_KEY, OP2_PRIVATE_KEY],
  chainId: 5,
  url: "https://rpc.ankr.com/eth_goerli",
  zksync: false,
};

export const Arbitrum = {
  accounts: [PRIVATE_KEY, OP1_PRIVATE_KEY, OP2_PRIVATE_KEY],
  chainId: 421613,
  url: "https://goerli-rollup.arbitrum.io/rpc",
  zksync: false,
};

export const Optimism = {
  accounts: [PRIVATE_KEY, OP1_PRIVATE_KEY, OP2_PRIVATE_KEY],
  chainId: 420,
  url: "https://optimism-goerli.blockpi.network/v1/rpc/public",
  zksync: false,
};

export const zkEVM = {
  accounts: [PRIVATE_KEY, OP1_PRIVATE_KEY, OP2_PRIVATE_KEY],
  chainId: 1442,
  url: "https://rpc.public.zkevm-test.net",
  zksync: false,
};

export const Metis = {
  accounts: [PRIVATE_KEY, OP1_PRIVATE_KEY, OP2_PRIVATE_KEY],
  chainId: 599,
  url: "https://goerli.gateway.metisdevops.link",
  zksync: false,
};

export const Scroll = {
  accounts: [PRIVATE_KEY, OP1_PRIVATE_KEY, OP2_PRIVATE_KEY],
  chainId: 534353,
  url: "https://alpha-rpc.scroll.io/l2",
  zksync: false,
};

export const Mantle = {
  accounts: [PRIVATE_KEY, OP1_PRIVATE_KEY, OP2_PRIVATE_KEY],
  chainId: 5001,
  url: "https://rpc.testnet.mantle.xyz",
  zksync: false,
};
