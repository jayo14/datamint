'use client'
import React, { createContext, useContext, useState, useEffect, useCallback } from 'react'
import { ethers, type Eip1193Provider } from 'ethers'

interface WindowWithEthereum extends Window {
  ethereum?: Eip1193Provider;
}

interface Web3ContextType {
  address: string | null;
  isConnected: boolean;
  isConnecting: boolean;
  connect: () => Promise<void>;
  disconnect: () => void;
  signer: ethers.Signer | null;
  provider: ethers.BrowserProvider | null;
  chainId: bigint | null;
}

const Web3Context = createContext<Web3ContextType | undefined>(undefined)

export function Web3Provider({ children }: { children: React.ReactNode }) {
  const [address, setAddress] = useState<string | null>(null)
  const [signer, setSigner] = useState<ethers.Signer | null>(null)
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null)
  const [chainId, setChainId] = useState<bigint | null>(null)
  const [isConnecting, setIsConnecting] = useState(false)

  const connect = useCallback(async () => {
    const win = window as unknown as WindowWithEthereum
    if (typeof window === 'undefined' || !win.ethereum) return
    setIsConnecting(true)
    try {
      const browserProvider = new ethers.BrowserProvider(win.ethereum)
      const accounts = await browserProvider.send('eth_requestAccounts', [])
      const network = await browserProvider.getNetwork()
      const browserSigner = await browserProvider.getSigner()
      setAddress(accounts[0]); setSigner(browserSigner); setProvider(browserProvider); setChainId(network.chainId)
    } catch (error) { console.error(error) } finally { setIsConnecting(false) }
  }, [])

  const disconnect = useCallback(() => { setAddress(null); setSigner(null); setProvider(null); setChainId(null) }, [])

  useEffect(() => {
    const checkConnection = async () => {
      const win = window as unknown as WindowWithEthereum
      if (typeof window !== 'undefined' && win.ethereum) {
        const browserProvider = new ethers.BrowserProvider(win.ethereum)
        const accounts = await browserProvider.listAccounts()
        if (accounts.length > 0) {
          const network = await browserProvider.getNetwork(); const browserSigner = await browserProvider.getSigner()
          setAddress(accounts[0].address); setSigner(browserSigner); setProvider(browserProvider); setChainId(network.chainId)
        }
      }
    }
    checkConnection()
  }, [])

  return <Web3Context.Provider value={{ address, isConnected: !!address, isConnecting, connect, disconnect, signer, provider, chainId }}>{children}</Web3Context.Provider>
}

export function useWeb3() {
  const context = useContext(Web3Context)
  if (context === undefined) throw new Error('useWeb3 must be used within a Web3Provider')
  return context
}
