import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: ["class"],
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "var(--background)",
        foreground: "var(--foreground)",
        slipe: {
          bg: "#080B10",
          surface: "#0D1117",
          panel: "#121721",
          card: "#151B26",
          cardHover: "#1C2433",
          border: "#202838",
          borderHover: "#2E3A50",
          borderLight: "#38455E",
          blue: "#2563EB",
          blueHover: "#1D4ED8",
          blueGlow: "#3B82F6",
          accent: "#60A5FA",
          cyan: "#06B6D4",
          emerald: "#10B981",
          amber: "#F59E0B",
          rose: "#EF4444",
          text: "#F8FAFC",
          muted: "#94A3B8",
          dim: "#64748B",
          faint: "#475569"
        }
      },
      fontFamily: {
        sans: [
          "'Inter'",
          "-apple-system",
          "BlinkMacSystemFont",
          "'Segoe UI'",
          "Roboto",
          "sans-serif",
        ],
        hero: [
          "'Inter'",
          "-apple-system",
          "BlinkMacSystemFont",
          "'Segoe UI'",
          "Roboto",
          "sans-serif",
        ],
        mono: [
          "'JetBrains Mono'",
          "'Fira Code'",
          "Consolas",
          "monospace"
        ]
      },
      boxShadow: {
        'subtle': '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        'shade-sm': '0 2px 8px -1px rgba(0, 0, 0, 0.04), 0 1px 4px -1px rgba(0, 0, 0, 0.02)',
        'shade-md': '0 8px 24px -4px rgba(0, 0, 0, 0.06), 0 3px 8px -2px rgba(0, 0, 0, 0.03)',
        'shade-lg': '0 16px 36px -6px rgba(0, 0, 0, 0.08), 0 6px 16px -3px rgba(0, 0, 0, 0.04)',
        'shade-xl': '0 24px 50px -10px rgba(0, 0, 0, 0.10), 0 10px 24px -4px rgba(0, 0, 0, 0.05)',
        'container-shade': '0 10px 30px -4px rgba(0, 0, 0, 0.07), 0 4px 12px -2px rgba(0, 0, 0, 0.03)',
        'container-shade-hover': '0 20px 40px -4px rgba(0, 0, 0, 0.10), 0 8px 18px -3px rgba(0, 0, 0, 0.05)',
        'hero-shade': '0 20px 50px -10px rgba(0, 0, 0, 0.08), 0 8px 25px -5px rgba(0, 0, 0, 0.04)',
      }
    },
  },
  plugins: [],
};
export default config;
