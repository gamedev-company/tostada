import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		proxy: {
			'/api': {
				target: 'http://localhost:4000',
				changeOrigin: true,
				cookieDomainRewrite: 'localhost'
			},
			'/users': {
				target: 'http://localhost:4000',
				changeOrigin: true,
				cookieDomainRewrite: 'localhost'
			},
			'/socket': {
				target: 'http://localhost:4000',
				changeOrigin: true,
				ws: true
			},
			'/live': {
				target: 'http://localhost:4000',
				changeOrigin: true,
				ws: true
			},
			'/assets': {
				target: 'http://localhost:4000',
				changeOrigin: true
			}
		}
	}
});
