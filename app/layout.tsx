import type { Metadata } from 'next';
import './globals.css';
import Script from 'next/script';

export const metadata: Metadata = {
  metadataBase: new URL('https://slipeai.com'),
  title: 'Slipe AI - Bring Your Photos Back to Life Without Losing Original Look',
  description:
    'Slipe AI offers world-class AI photo restoration, super-resolution enhancement, video remastering, and creative assistance. Enhance without losing original look.',
  keywords: [
    'AI photo enhancer',
    'photo restoration',
    'face recovery',
    'video remaster',
    'Slipe AI',
    'Topaz AI',
    'old photo repair',
  ],
  authors: [{ name: 'Pace AI Technologies (OPC) Private Limited' }],
  openGraph: {
    title: 'Slipe AI - AI Photo & Video Enhancer',
    description: 'Bring your photos back to life without losing original look!',
    url: 'https://slipeai.com',
    siteName: 'Slipe AI',
    images: [
      {
        url: '/assets/images/premium_showcase_1.jpg',
        width: 1200,
        height: 630,
        alt: 'Slipe AI Before and After Portrait Enhancement',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  icons: {
    icon: '/assets/icons/app_icon.png',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
      </head>
      <body className="min-h-screen bg-black text-white antialiased selection:bg-white selection:text-black">
        {children}
        {/* Razorpay Checkout Script */}
        <Script
          src="https://checkout.razorpay.com/v1/checkout.js"
          strategy="lazyOnload"
        />
      </body>
    </html>
  );
}
