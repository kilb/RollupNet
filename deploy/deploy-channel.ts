import { ethers } from "hardhat";
// load env file
import dotenv from "dotenv";
dotenv.config();

const contractName = process.env.CONTRACT || "";

async function main() {
  const manager = await ethers.getContractFactory(contractName);

  const contract = await manager.deploy("0x88736e6d0Cb9C016A916e0D5827dCBD6BAF1c192");

  console.log(
    `Contract ${contractName} was deployed to ${contract.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
