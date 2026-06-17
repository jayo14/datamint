import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Navbar } from "@/components/layout/Navbar";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  other: {
    "talentapp:project_verification": "8dfd96d3f3ffb967bf11deda1562a1f7d07cb57d34f94b81bc76bdb393db635d4369cfe6c777876e5bfd1c944f8af0b9cc84458fb270ba6279ecd9cfa8c29aa8"
  },
  title: "DataMint | AI Dataset Marketplace",
  description: "On-chain AI dataset marketplace powered by human contributors + instant Celo payouts.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" >
      <body className={`${inter.className} min-h-screen bg-background font-sans antialiased`}>
        <div className="relative flex min-h-screen flex-col">
          <Navbar />
          <main className="flex-1">
            <div className="container py-6">
              {children}
            </div>
          </main>
        </div>
      </body>
    </html>
  );
}
