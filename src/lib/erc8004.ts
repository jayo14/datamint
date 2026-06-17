import { ethers } from 'ethers'

const ERC8004_REGISTRY_ADDRESS = '0x8Ef622e0e9803b98305fED23E666b6E81f9D466F'

const ERC8004_ABI = [
  "function register(string calldata name, string calldata metadataURI) external returns (uint256 agentId)",
  "function getAgent(uint256 agentId) external view returns (string memory name, address owner, string memory metadataURI, uint256 registeredAt)",
  "function agentOf(address owner) external view returns (uint256 agentId)"
]

export async function registerAgent(signer: ethers.Signer, name: string, metadataURI: string) {
  const registry = new ethers.Contract(ERC8004_REGISTRY_ADDRESS, ERC8004_ABI, signer)
  const tx = await registry.register(name, metadataURI)
  const receipt = await tx.wait()
  return receipt
}

export async function getAgentId(signer: ethers.Signer) {
  const registry = new ethers.Contract(ERC8004_REGISTRY_ADDRESS, ERC8004_ABI, signer)
  const address = await signer.getAddress()
  try {
    const agentId = await registry.agentOf(address)
    return agentId.toString()
  } catch {
    return null
  }
}
