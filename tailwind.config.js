/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      fontFamily: {
        'sans': ['Roboto', 'ui-sans-serif', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Arial', 'Noto Sans', 'sans-serif'],
        'sports': ['Sports World', 'sans-serif'],
        'seven': ['Seven Segment', 'serif'],
      },
    },
  },
  plugins: [],
}