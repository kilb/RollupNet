import { ethers } from "hardhat";
// load env file
import dotenv from "dotenv";
dotenv.config();

const contractName = process.env.CONTRACT || "";

async function main() {
  const manager = await ethers.getContractFactory(contractName);

  const contract = await manager.deploy("0xEe74e477204A9Cf28bfd235a46A07fba1434D2F4");

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
