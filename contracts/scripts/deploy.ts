import pkg from "hardhat";
const { ethers } = pkg;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Alfajores cUSD address
  const cUSD_ADDRESS = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

  const DataMintEscrow = await ethers.getContractFactory("DataMintEscrow");
  const escrow = await DataMintEscrow.deploy(cUSD_ADDRESS);

  await escrow.waitForDeployment();

  console.log("DataMintEscrow deployed to:", await escrow.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
