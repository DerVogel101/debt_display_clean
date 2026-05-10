# Debt Display

Debt Display is a Flutter web app with a Python/FastAPI backend for tracking
shared bills, recipients, payments, tags, file uploads, and unpaid summaries.

The backend serves both the JSON/protobuf API under `/api` and the built Flutter
web app from `backend/web`.

## Project Layout

- `lib/` - Flutter application code.
- `assets/env/app.env.example` - frontend runtime configuration template.
- `backend/` - FastAPI backend, Auth0 validation, SQLite models, API routes, and
  static frontend serving.
- `backend/.env.example` - backend runtime configuration template.
- `proto/` - source protobuf definitions.
- `lib/generated/` and `backend/proto/` - generated protobuf code.
- `tests/` - Python backend tests.
- `test/` - Flutter tests.
- `Dockerfile` and `docker-compose.yml` - container deployment files.

## Runtime Configuration

Create config files from the examples after pulling the repository:

```powershell
Copy-Item assets\env\app.env.example assets\env\app.env
Copy-Item backend\.env.example backend\.env
```

Keep deployment-specific values in these files instead of in `docker-compose.yml`.
The frontend reads `assets/env/app.env` during the Flutter web build, and the
backend reads `backend/.env` at runtime.

Important backend settings:

- `AUTH0_DOMAIN` and `AUTH0_AUDIENCE` configure API token validation.
- `DATABASE_URL` defaults to SQLite.
- `UPLOAD_DIR` stores uploaded receipt/files.
- `FRONTEND_STATIC_DIR` points to the Flutter web build served by FastAPI.
- `GENERATE_TEST_DATA_ON_STARTUP` is enabled by default in code; set it to
  `false` before using a database with real data.
- `ALLOWED_ORIGINS` should include the frontend origin in development and the
  production domain in deployment.

Important frontend settings:

- `BACKEND_URL_DEBUG` is used by local Flutter web runs.
- `BACKEND_URL_RELEASE` and `FRONTEND_URL_RELEASE` should match the deployed
  public URL.
- Auth0 frontend settings must match the Auth0 application configuration.

## Development

Install Python dependencies through `uv`:

```powershell
uv sync
```

Run the backend on port `3300`:

```powershell
uv run python -m backend
```

Run the Flutter web app on port `3000`:

```powershell
flutter run -d chrome --web-port=3000
```

The Makefile contains the same development shortcuts:

```powershell
make dev-backend
make dev-flutter
```

## Build The Flutter Web App

The backend serves static files from `backend/web`. Build and copy the Flutter
release assets there with:

```powershell
make release-flutter
```

`backend/web` is ignored by git except for `.gitkeep`. Local development can
populate it with `make release-flutter`; the Docker image builds the Flutter web
assets itself and copies them into the runtime image.

## Protobuf Generation

After changing files in `proto/`, regenerate both Python and Dart protobuf
outputs:

```powershell
make proto
```

This requires `protoc` and `protoc-gen-dart` to be available on `PATH`.

## Tests

Run backend tests:

```powershell
uv run pytest
```

Run Flutter analysis and tests:

```powershell
flutter analyze
flutter test
```

## Docker

Build the container. The Dockerfile runs the Flutter web release build first,
then copies the generated assets into the backend runtime image:

```powershell
docker build -t debt-display .
```

Run it locally with host-mounted data after creating `backend/.env` and
`assets/env/app.env`:

```powershell
docker run --rm -p 3300:3300 -v ${PWD}\data:/data debt-display
```

Inside the container:

- SQLite database: `/data/database.sqlite`
- Uploads: `/data/uploads`

## Portainer Deployment

The included `docker-compose.yml` is intended for Portainer stacks. It bind
mounts a host directory into `/data` so SQLite and uploads survive container
updates. Environment values are intentionally not stored in the Compose file.

On the Linux host, create the data directory:

```bash
mkdir -p /opt/debt-display/data/uploads
```

In Portainer, deploy this repository as a stack and set:

```text
DEBT_DISPLAY_DATA_DIR=/opt/debt-display/data
```

After pulling the repository on the deployment host, create and edit the config
files before building or redeploying the stack:

```bash
cp assets/env/app.env.example assets/env/app.env
cp backend/.env.example backend/.env
```

Set deployment values in those files:

- `assets/env/app.env`: `BACKEND_URL_RELEASE`, `FRONTEND_URL_RELEASE`,
  `AUTH0_DOMAIN`, `AUTH0_CLIENT_ID`, and `AUTH0_AUDIENCE`.
- `backend/.env`: `AUTH0_DOMAIN`, `AUTH0_AUDIENCE`, `ALLOWED_ORIGINS`, and
  `GENERATE_TEST_DATA_ON_STARTUP=false`.

Expose port `3300` directly or put a reverse proxy in front of it.
