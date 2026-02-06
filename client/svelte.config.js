import adapter from '@sveltejs/adapter-static';

const dev = process.env.NODE_ENV !== 'production';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	kit: {
		adapter: adapter({
			// Build output goes to Phoenix priv/static/app
			pages: '../server/priv/static/app',
			assets: '../server/priv/static/app',
			fallback: 'index.html',
			precompress: true
		}),
		paths: {
			// Only use /app base path in production (when served by Phoenix)
			base: dev ? '' : '/app'
		}
	}
};

export default config;
