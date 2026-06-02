## What this repository is

This repo contains **no application code**. It *assembles* the Fragalysis stack by combining two
externally-built container images, selected by environment variables / build args:

- [fragalysis-backend](https://github.com/xchem/fragalysis-backend) — Django + RDKit + Celery
- [fragalysis-frontend](https://github.com/xchem/fragalysis-frontend) — pre-compiled web bundles

The `Dockerfile` is a two-stage build: it pulls the frontend image, then pulls the
backend image and copies the frontend's `/frontend` directory into the backend at
`${APP_ROOT}/frontend` (`/code/frontend`), symlinking the bundles into `/code/static/bundles`.
The container entrypoint and runtime behaviour (`docker-entrypoint.sh`, `launch-stack.sh`)
belong to the **backend** image, not this repo.

Because there is no source to lint or unit-test here, day-to-day work is: changing image tags,
adjusting Docker/compose configuration, and editing the GitHub Actions workflow.

## Key build args / image selection

Set in `Dockerfile` and overridden by `.github/workflows/build-main.yaml`:

- `BE_NAMESPACE` / `BE_IMAGE_TAG` — which backend image to pull (default namespace `xchem`)
- `FE_NAMESPACE` / `FE_IMAGE_TAG` — which frontend image to pull (default namespace `xchem`)
- `STACK_NAMESPACE` / `STACK_VERSION` — where to publish and what to tag the assembled stack image

These origins are also baked into the runtime image as `ENV` vars for diagnostics
(visible at the bottom of the Fragalysis menu).

## Local development

```bash
docker-compose up -d     # launch stack + postgres + neo4j + redis
docker-compose down      # tear everything down
```

`docker-compose.yml` is the maintained compose file (Postgres 12, neo4j 4.4, Redis 7, plus the `stack`
service built from this `Dockerfile`). It runs Celery eagerly (`CELERY_TASK_ALWAYS_EAGER: True`) and
wires Keycloak (OIDC) and Squonk2 config via environment variables — supply secrets via the shell
environment, never commit them. Persistent data lives under `./data` (gitignored, auto-created).
`docker-compose.dev.yml` is an older/simpler variant; treat `docker-compose.yml` as authoritative.

## Releasing (this is the core workflow)

Builds and deployments are driven entirely by GitHub Actions (`build-main.yaml`) and AWX/Kubernetes:

- **Every push of a tag** builds the stack image and (if `TRIGGER_AWX=yes`) deploys to **staging**.
- **Only tags of the form `N.N.N`** (e.g. `2026.06.1`) additionally deploy to **production**.
- An OSV vulnerability scan runs on every build (informational; allowed to fail).

**Before cutting a production release you MUST update the backend/frontend tags first**,
then tag:

1. Create matching releases in fragalysis-frontend and fragalysis-backend (tag format `YYYY.MM.#`).
2. Edit `env.BE_IMAGE_TAG` / `env.FE_IMAGE_TAG` near the top of `.github/workflows/build-main.yaml`, and commit directly to `master`.
3. Create a new release/tag for this repo. Tags need **not** match across the three repos.
