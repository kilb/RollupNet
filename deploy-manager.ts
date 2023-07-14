import { ethers } from "hardhat";

async function main() {
  const manager = await ethers.getContractFactory("L1Manager");

  const contract = await manager.deploy();

  console.log(
    `L1 Manager was deployed to ${contract.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
