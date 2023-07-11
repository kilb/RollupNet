const hre = require("hardhat");
const fs = require('fs')

const NUM_WALLET = 10;

async function main() {
    let provider = new hre.ethers.providers.JsonRpcProvider("http://127.0.0.1:8545");
    let account = await provider.getSigner(0);
    let wallets = await hre.ethers.getSigners()

    // transfer to 10 wallets
    for (let i=0; i<NUM_WALLET; i++) {
        const txResponse = await account.sendTransaction({
            to: wallets[i].address,
            value: hre.ethers.utils.parseEther('1')
        })
    }

    // deploy the contract using the first wallet
    const db = await hre.ethers.getContractFactory("RegPrivDB");
    const regDb = await db.connect(wallets[0]).deploy()
    await regDb.deployed()
    console.log("DB deployed to:", regDb.address);
    const jsonData = JSON.stringify({"RegPrivDB": regDb.address})
    const jsonFile = "contracts/deploy.json"
    fs.writeFileSync(jsonFile, jsonData)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
