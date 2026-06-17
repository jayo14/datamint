import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Navbar } from "@/components/layout/Navbar";
import { Web3Provider } from "@/hooks/useWeb3";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "DataMint | AI Dataset Marketplace",
  description: "On-chain AI dataset marketplace powered by human contributors + instant Celo payouts.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className={`${inter.className} min-h-screen bg-background font-sans antialiased`}>
        <Web3Provider>
          <div className="relative flex min-h-screen flex-col">
            <Navbar />
            <main className="flex-1">
              <div className="container py-6 mx-auto">
                {children}
              </div>
            </main>
          </div>
        </Web3Provider>
      </body>
    </html>
  );
}
