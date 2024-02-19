import { Metadata, Viewport } from "next";

import { siteConfig } from "@/lib/site";

import "@/app/globals.css";
import "@rainbow-me/rainbowkit/styles.css";

import { cn } from "@/lib/utils";
import { Providers } from "@/components/providers";

export const metadata: Metadata = {
  title: { default: "Intents Engine", template: `%s | ${siteConfig.name}` },
  description: siteConfig.description,
  authors: [
    {
      name: siteConfig.author,
      url: siteConfig.githubUrl,
    },
  ],
  generator: "Next.js",
  keywords: siteConfig.keywords,
  icons: {
    icon: "/logo.webp",
    apple: "/apple-touch-icon.png",
  },
  metadataBase: new URL(siteConfig.baseUrl),
  openGraph: {
    type: "website",
    title: siteConfig.name,
    description: siteConfig.description,
    url: siteConfig.baseUrl,
    siteName: siteConfig.name,
  },
  twitter: {
    card: "summary_large_image",
    site: siteConfig.baseUrl,
    siteId: siteConfig.twitterId,
    creator: siteConfig.author,
    creatorId: siteConfig.twitterId,
    description: siteConfig.description,
    title: siteConfig.name,
  },
};

export const viewport: Viewport = {
  width: "device-width", // This will make the width of the page follow the screen-width of the device (which will vary depending on the device).
  height: "device-height", // Similar to the above, but for height.
  initialScale: 1, // This defines the ratio between the device width (device-width in portrait mode or device-height in landscape mode) and the viewport size.
  minimumScale: 1, // This defines the minimum zoom level to which the user can zoom out. Keeping this as 1 disallows the user to zoom out beyond the initial scale.
  maximumScale: 1, // This defines the maximum zoom level to which the user can zoom in. This can be set as per your requirement.
  userScalable: false, // This allows the user to zoom in or out on the webpage. 'no' will prevent the user from zooming.
  viewportFit: "cover", // This can be set to 'auto', 'contain', or 'cover'. 'cover' implies that the viewport should cover the whole screen.
  interactiveWidget: "resizes-visual", // This can be set to 'resizes-visual', 'resizes-content', or 'overlays-content'. 'resizes-visual' implies that the widget can resize the visual viewport.
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      className={cn(
        "min-h-full bg-black text-white w-screen",
        "default-font",
      )}
      suppressHydrationWarning
    >
      <head>
      <link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
<link href="https://fonts.googleapis.com/css2?family=VT323&display=swap" rel="stylesheet" />

      </head>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
