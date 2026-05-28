import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AstralCloud",
  description: "Your personal cloud",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
