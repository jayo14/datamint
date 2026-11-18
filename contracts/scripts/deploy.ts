import pkg from "hardhat";
const { ethers } = pkg;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Require cUSD token address explicitly from environment configuration
  const cUSD_ADDRESS = process.env.CUSD_TOKEN_ADDRESS;
  if (!cUSD_ADDRESS) {
    throw new Error(
      "Missing CUSD_TOKEN_ADDRESS in environment. Specify the public token contract address for target network."
    );
  }

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
