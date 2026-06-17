import { ethers } from 'ethers'

const ESCROW_ABI = [
  "function createDataset(uint256 _datasetId, uint256 _rewardPerTask, uint256 _totalRequired) external",
  "function fundDataset(uint256 _datasetId, uint256 _amount) external",
  "function getDatasetBalance(uint256 _datasetId) external view returns (uint256)",
  "event DatasetCreated(uint256 indexed datasetId, address indexed creator, uint256 rewardPerTask, uint256 totalRequired)",
  "event DatasetFunded(uint256 indexed datasetId, uint256 amount)"
]

const ERC20_ABI = [
  "function approve(address spender, uint256 amount) public returns (bool)",
  "function allowance(address owner, address spender) public view returns (uint256)"
]

const ESCROW_ADDRESS = process.env.NEXT_PUBLIC_ESCROW_ADDRESS || ""
const CUSD_ADDRESS = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1" // Alfajores

export async function getContract(signer: ethers.Signer) {
  return new ethers.Contract(ESCROW_ADDRESS, ESCROW_ABI, signer)
}

export async function getCUSDContract(signer: ethers.Signer) {
  return new ethers.Contract(CUSD_ADDRESS, ERC20_ABI, signer)
}

export async function fundDataset(
  signer: ethers.Signer,
  datasetId: number,
  rewardPerTask: number,
  totalRequired: number
) {
  const escrow = await getContract(signer)
  const cusd = await getCUSDContract(signer)

  const totalAmount = ethers.parseEther((rewardPerTask * totalRequired).toString())

  // Create dataset on chain first if needed (simplified for MVP: just do it)
  try {
    const tx1 = await escrow.createDataset(datasetId, ethers.parseEther(rewardPerTask.toString()), totalRequired)
    await tx1.wait()
  } catch (e) {
    console.log("Dataset might already exist on chain", e)
  }

  // Approve cUSD
  const tx2 = await cusd.approve(ESCROW_ADDRESS, totalAmount)
  await tx2.wait()

  // Fund dataset
  const tx3 = await escrow.fundDataset(datasetId, totalAmount)
  const receipt = await tx3.wait()

  return receipt.hash
}
