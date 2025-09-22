import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		port: 5173,
		host: true
	},
	build: {
		// Otimizações de build
		target: 'esnext',
		minify: 'terser',
		sourcemap: false,
		rollupOptions: {
			output: {
				// Chunking otimizado
				manualChunks: {
					// Vendor chunks separados
					vendor: ['@supabase/supabase-js'],
					charts: ['chart.js', 'svelte-chartjs'],
					utils: ['date-fns', 'jsdom', 'jspdf', 'jspdf-autotable', 'xlsx']
				},
				// Nomes de arquivos otimizados
				chunkFileNames: 'assets/[name]-[hash].js',
				entryFileNames: 'assets/[name]-[hash].js',
				assetFileNames: 'assets/[name]-[hash].[ext]'
			}
		},
		// Configurações de terser para minificação
		terserOptions: {
			compress: {
				drop_console: true, // Remove console.log em produção
				drop_debugger: true
			}
		}
	},
	// Otimizações de desenvolvimento
	optimizeDeps: {
		include: ['@supabase/supabase-js', 'chart.js', 'svelte-chartjs']
	}
});
