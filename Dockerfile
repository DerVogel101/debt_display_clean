FROM ghcr.io/cirruslabs/flutter:stable AS flutter-build

WORKDIR /src

COPY pubspec.yaml pubspec.lock ./
RUN git config --global --add safe.directory /sdks/flutter
RUN flutter pub get

COPY analysis_options.yaml l10n.yaml ./
COPY assets ./assets
COPY lib ./lib
COPY web ./web
RUN flutter build web --release --pwa-strategy=none --no-wasm-dry-run --no-web-resources-cdn

FROM ghcr.io/astral-sh/uv:python3.14-bookworm-slim

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PATH="/app/.venv/bin:$PATH" \
    BACKEND_HOST=0.0.0.0 \
    BACKEND_PORT=3300 \
    DATABASE_URL=sqlite+aiosqlite:////data/database.sqlite \
    UPLOAD_DIR=/data/uploads \
    FRONTEND_STATIC_DIR=/app/backend/web

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY backend ./backend
COPY --from=flutter-build /src/build/web ./backend/web
RUN mkdir -p /data/uploads

EXPOSE 3300

CMD ["python", "-m", "backend"]
