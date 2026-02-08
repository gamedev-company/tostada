# Tostada

Phoenix + SvelteKit boilerplate with authenticated sockets, admin backend, and a production-ready build pipeline.

## Quick Start

```bash
make install
make db.setup
make dev
```

- Phoenix runs at `http://localhost:4000`
- SvelteKit dev runs at `http://localhost:5173`
- The Svelte app is served from `/app` in production (adapter-static builds to Phoenix `priv/static/app`).

## Auth + Sockets

- Browser auth uses session cookies (Phoenix HTML endpoints).
- The SPA can call `GET /api/socket-token` to retrieve a short-lived socket token.
- The JS socket client falls back to session auth when cookies are available.

## Default Threlte Scene

The Svelte app ships with a minimal Threlte setup that mirrors good defaults from the Threlte docs:

- Full-bleed `<Canvas>` with a default `PerspectiveCamera`.
- A single floating box that animates in the render loop (`useFrame`).
- Two directional lights + ambient light for readable shading.
- `OrbitControls` with zoom/pan disabled for a clean demo.
- Only UI chrome is the login/register icon buttons.

The scene lives at `client/src/routes/+page.svelte`.

## Extending The Scene

Common starting points:

1. Add a new scene component
   - Create `client/src/lib/scenes/MyScene.svelte`
   - Import it into `client/src/routes/+page.svelte`
   - Swap the mesh for your new scene component

2. Add state or inputs
   - Use Svelte stores for global state
   - Use `useFrame` for per-frame updates
   - Use `@threlte/extras` controls/helpers as needed

3. Add assets
   - Put textures/models under `client/static/`
   - Load them with Three loaders or `@threlte/extras`

4. Multiple scenes or routes
   - Add a new route under `client/src/routes/your-scene/+page.svelte`
   - Keep `/app` as the default entry and link between scenes

## Admin Backend

- `/admin` (requires admin user)
- User management: list + edit `display_name` and `is_admin`

## Build + Deploy

```bash
make build
make deploy.build
make deploy.release
```

Deployment scripts live in `server/scripts/deploy/` and are intentionally generic. Update service paths, server name, and environment variables to match your infrastructure.

## Model Pipeline (Optional)

```bash
make models.build
```

Converts GLTF/GLB assets in `obj/` to Svelte components and static files. Assets are served from `/models` (Svelte build output) and `/obj` (large, undigested assets).

If you plan to use the generated Svelte components, add the Threlte/Three dependencies you need (the generator uses `@threlte/gltf`).

## Initialize A New Project

```bash
make new APP_NAME=my_app APP_MODULE=MyApp APP_HUMAN="My App" APP_HOST=myapp.example.com
```

- `APP_NAME` is the OTP app name (snake_case)
- `APP_MODULE` is the Elixir module prefix
- `APP_HUMAN` is the display name used in UI copy
- `APP_HOST` updates default host references in configs/templates

## License

MIT (adjust as needed)
