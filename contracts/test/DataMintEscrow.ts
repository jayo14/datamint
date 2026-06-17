import { expect } from "chai";
import pkg from "hardhat";
const { ethers } = pkg;

describe("DataMintEscrow", function () {
  let escrow: any;
  let token: any;
  let owner: any;
  let creator: any;
  let contributor: any;

  beforeEach(async function () {
    [owner, creator, contributor] = await ethers.getSigners();

    const MockToken = await ethers.getContractFactory("MockToken");
    token = await MockToken.deploy("Mock cUSD", "cUSD");

    const DataMintEscrow = await ethers.getContractFactory("DataMintEscrow");
    escrow = await DataMintEscrow.deploy(await token.getAddress());

    await token.transfer(creator.address, ethers.parseEther("100"));
  });

  it("Should create and fund a dataset", async function () {
    const datasetId = 1;
    const reward = ethers.parseEther("1");
    const total = 10;

    await escrow.connect(creator).createDataset(datasetId, reward, total);

    await token.connect(creator).approve(await escrow.getAddress(), reward * BigInt(5));
    await escrow.connect(creator).fundDataset(datasetId, reward * BigInt(5));

    expect(await escrow.getDatasetBalance(datasetId)).to.equal(reward * BigInt(5));
  });

  it("Should approve work and release payment", async function () {
    const datasetId = 1;
    const reward = ethers.parseEther("1");
    const total = 10;

    await escrow.connect(creator).createDataset(datasetId, reward, total);
    await token.connect(creator).approve(await escrow.getAddress(), reward);
    await escrow.connect(creator).fundDataset(datasetId, reward);

    const initialBalance = await token.balanceOf(contributor.address);
    await escrow.connect(creator).approveWork(datasetId, contributor.address);
    const finalBalance = await token.balanceOf(contributor.address);

    expect(finalBalance - initialBalance).to.equal(reward);
    expect(await escrow.getDatasetBalance(datasetId)).to.equal(0);
  });

  it("Should prevent non-creator from approving work", async function () {
    const datasetId = 1;
    const reward = ethers.parseEther("1");
    await escrow.connect(creator).createDataset(datasetId, reward, 10);

    await expect(
      escrow.connect(contributor).approveWork(datasetId, contributor.address)
    ).to.be.revertedWith("Only creator can approve");
  });

  it("Should prevent payout if insufficient funds", async function () {
    const datasetId = 1;
    const reward = ethers.parseEther("1");
    await escrow.connect(creator).createDataset(datasetId, reward, 10);

    await expect(
      escrow.connect(creator).approveWork(datasetId, contributor.address)
    ).to.be.revertedWith("Insufficient escrow balance");
  });
});
