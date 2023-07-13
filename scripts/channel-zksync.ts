import { Provider } from "zksync-web3";
import * as ethers from "ethers";

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