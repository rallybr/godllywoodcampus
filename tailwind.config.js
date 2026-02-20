/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    screens: {
      'xs': '475px',
      'sm': '640px',
      'md': '768px',
      'lg': '1024px',
      'xl': '1280px',
      '2xl': '1536px',
    },
    extend: {
      colors: {
        // Paleta futurista baseada na imagem
        neon: {
          blue: '#00BFFF',
          'blue-dark': '#0080FF',
          purple: '#8A2BE2',
          'purple-dark': '#9932CC',
          magenta: '#FF1493',
          'magenta-light': '#FF69B4',
          white: '#F0F8FF',
          'white-bright': '#FFFFFF'
        },
        dark: {
          900: '#000000',
          800: '#0a0a0a',
          700: '#1a1a1a',
          600: '#2a2a2a',
          500: '#3a3a3a'
        },
        primary: {
          50: '#f0f8ff',
          100: '#e0f2ff',
          200: '#bae6ff',
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#00BFFF', // Neon blue
          600: '#0080FF', // Neon blue dark
          700: '#0066cc',
          800: '#0052a3',
          900: '#003d7a'
        },
        secondary: {
          50: '#faf5ff',
          100: '#f3e8ff',
          200: '#e9d5ff',
          300: '#d8b4fe',
          400: '#c084fc',
          500: '#8A2BE2', // Neon purple
          600: '#9932CC', // Neon purple dark
          700: '#7c3aed',
          800: '#6b21a8',
          900: '#581c87'
        },
        accent: {
          50: '#fdf2f8',
          100: '#fce7f3',
          200: '#fbcfe8',
          300: '#f9a8d4',
          400: '#f472b6',
          500: '#FF1493', // Neon magenta
          600: '#FF69B4', // Neon magenta light
          700: '#ec4899',
          800: '#db2777',
          900: '#be185d'
        },
        // Toque feminino: rosa e lavanda suaves (branco continua predominante)
        rose: {
          soft: '#fce7f3',
          light: '#fbcfe8',
          DEFAULT: '#e8a0bf',
          medium: '#d973a3',
          dark: '#be185d'
        },
        lavender: {
          soft: '#f5f3ff',
          light: '#ede9fe',
          DEFAULT: '#c084fc',
          medium: '#a78bfa',
          dark: '#7c3aed'
        }
      },
      fontFamily: {
        'neon': ['Orbitron', 'monospace'],
        'sans': ['Inter', 'system-ui', 'sans-serif']
      },
      boxShadow: {
        'neon': '0 0 5px currentColor, 0 0 10px currentColor, 0 0 15px currentColor',
        'neon-blue': '0 0 5px #00BFFF, 0 0 10px #00BFFF, 0 0 15px #00BFFF',
        'neon-purple': '0 0 5px #8A2BE2, 0 0 10px #8A2BE2, 0 0 15px #8A2BE2',
        'neon-magenta': '0 0 5px #FF1493, 0 0 10px #FF1493, 0 0 15px #FF1493'
      },
      animation: {
        'glow': 'glow 2s ease-in-out infinite alternate',
        'pulse-neon': 'pulse-neon 2s cubic-bezier(0.4, 0, 0.6, 1) infinite'
      },
      keyframes: {
        glow: {
          '0%': { boxShadow: '0 0 5px currentColor, 0 0 10px currentColor, 0 0 15px currentColor' },
          '100%': { boxShadow: '0 0 10px currentColor, 0 0 20px currentColor, 0 0 30px currentColor' }
        },
        'pulse-neon': {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.8' }
        }
      }
    }
  },
  plugins: []
};