import { Provider } from "zksync-web3";
import * as ethers from "ethers";

import MetaData from "./types"

// load env file
import dotenv from "dotenv";
dotenv.config();

// load contract artifact. Make sure to compile first!
import * as ContractArtifact from "../artifacts-zk/contracts/ZKChannel.sol/ZKChannel.json";

global.logLevel = "debug";

const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

if (!PRIVATE_KEY)
  throw "⛔️ Private key not detected! Add it to the .env file!";

// Address of the contract on zksync testnet
const CONTRACT_ADDRESS = "0xB99339B6F58A4E16C040C76E11dD219d1Ed39138";

if (!CONTRACT_ADDRESS) throw "⛔️ Contract address not provided";

console.log(`The message is 1`);

// An example of a deploy script that will deploy and call a simple contract.
async function getChannels() {
  console.log(`Running script to interact with contract ${CONTRACT_ADDRESS}`);

  // Initialize the provider.
  // @ts-ignore
  const provider = new Provider("https://zksync2-testnet.zksync.dev");
  const signer = new ethers.Wallet(PRIVATE_KEY, provider);

  const meta = new MetaData(
    ["0x0555557997258902185572902627555431450621", "0x0555557997258902185572902627555431450621"],
    ["0x2b4D61D87015a7E04Aca172c146742961c610D3E", "0x2b4D61D87015a7E04Aca172c146742961c610D3E"],
    [1, 2],
    ["0x1", "0x1"],
    600, 7200, 1200, 3600, 5400, 600,
    ['0x56bc75e2d63100000', '0x0'],
    ['0x0', '0xad78ebc5ac6200000']
  );
  
  const sig = await meta.sign(signer);

  console.log(sig.v, sig.r, sig.s);

  // Initialize contract instance
  const contract = new ethers.Contract(
    CONTRACT_ADDRESS,
    ContractArtifact.abi,
    signer
  );

  console.log(`The message is 1`);

  

  // Read message from contract
  console.log(`The message is ${await contract.channels(1)}`);

//   // send transaction to update the message
//   const newMessage = "Hello people!";
//   const tx = await contract.setGreeting(newMessage);

//   console.log(`Transaction to change the message is ${tx.hash}`);
//   await tx.wait();

//   // Read message after transaction
//   console.log(`The message now is ${await contract.greet()}`);
}

getChannels();