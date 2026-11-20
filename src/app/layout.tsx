import type { Metadata } from "next";
import { Inter, Bricolage_Grotesque } from "next/font/google";
import "./globals.css";
import { AppShell } from "@/components/layout/AppShell";
import { Web3Provider } from "@/hooks/useWeb3";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

const bricolageGrotesque = Bricolage_Grotesque({
  subsets: ["latin"],
  weight: ["500", "600", "700"],
  variable: "--font-bricolage",
  display: "swap",
});

export const metadata: Metadata = {
  title: "DataMint | AI Dataset Marketplace",
  description: "On-chain AI dataset marketplace powered by human contributors + instant Celo payouts.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${inter.variable} ${bricolageGrotesque.variable}`}>
      <body className={`${inter.className} min-h-screen bg-background font-sans antialiased`}>
        <Web3Provider>
          <AppShell>
            {children}
          </AppShell>
        </Web3Provider>
      </body>
    </html>
  );
}
