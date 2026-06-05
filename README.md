# Tostada

The shared Phoenix backend for [Tostada projects](https://www.npmjs.com/package/tostada-cli) — headless JSON + WebSocket API, no LiveView, no server-rendered HTML.

**You don't usually clone this repo directly.** It gets fetched by `tostada-cli` during scaffolding and combined with a client variant of your choice.

```bash
npx tostada-cli@latest create MyApp --variant react-shadcn
```

The CLI scaffolds a fresh project, fetches this boilerplate, drops your chosen client into `client/`, codemods names, and installs deps. See the [installer docs](https://gamedev-company.github.io/tostada-site/docs/installers) for variant options.

## What this repo contains

The bits that get spliced into every generated Tostada project:

- `server/` — Phoenix 1.8 backend (JSON auth, channels, SPA serving)
- `scripts/` — shared scripts (`build-models.sh` for Threlte variants)
- `Makefile` — shared orchestration (`make dev`, `make build`, `make db.setup`)
- `README.md` — project-level docs (regenerated per-project after scaffolding)

There is **no `client/`** in this repo. Client templates live in the [`tostada-cli`](https://github.com/gamedev-company/tostada-cli) repo under `packages/tostada/templates/clients/`.

## The Phoenix backend

Headless API + WebSocket only:

- `POST /api/auth/register`, `/api/auth/login`, `/api/auth/logout`
- `POST /api/auth/forgot-password`, `/api/auth/reset-password` (Swoosh-backed email delivery, dev mailbox at `/dev/mailbox`)
- `GET /api/me` — current user JSON or 401
- `GET /api/socket-token` — short-lived bearer for WebSocket handshake
- `GET /app/*` — serves the SPA shell in production from `priv/static/app/`
- WebSocket at `/socket` — authenticated via either the HttpOnly session cookie or a bearer token

**Not included:** no LiveView, no `phoenix_html`, no tailwind/esbuild on the server, no HTML auth pages, no gettext. The client owns all UI.

11 ExUnit tests cover the auth surface. Run with `mix test` from `server/`.

## Hacking on the backend in isolation

If you want to iterate on the Phoenix server without going through the CLI:

```bash
cd server
mix deps.get
mix ecto.setup
mix phx.server   # http://localhost:4000
```

`/api/*` and `/socket` will be live. You won't have a SPA to serve at `/app` until you `npm run build` a client into `server/priv/static/app/`.

## Hacking on the CLI's variant pipeline

When iterating on `tostada-cli` against unpushed changes in this repo, set the env var:

```bash
TOSTADA_LOCAL_TEMPLATE=/path/to/tostada \
  node /path/to/tostada-cli/packages/tostada/dist/bin.js create TestApp --variant <id>
```

The CLI will copy this local dir instead of fetching the GitHub tarball.

## Architecture decisions

The headless Phoenix decision: auth UI (login forms, password input, error messages) is a client concern. Phoenix keeps the irreducible server pieces — bcrypt password hashing, session token issuance, email delivery, schema. The session token rides in an HttpOnly cookie (XSS-immune); short-lived bearer tokens are minted for non-cookie clients via `/api/socket-token`. See [docs/reference/auth-system](https://gamedev-company.github.io/tostada-site/docs/reference/auth-system) for the full rationale.

## License

MIT
