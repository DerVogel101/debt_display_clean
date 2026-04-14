.PHONY: proto dev-backend dev-flutter

# ── Protobuf codegen ──────────────────────────────────────────────────────────
proto:
	python -m grpc_tools.protoc -I proto/ --python_out=backend/proto/ proto/auth.proto
	protoc -I proto/ --dart_out=lib/generated/ proto/auth.proto

# ── Dev servers ───────────────────────────────────────────────────────────────
# Backend on :3300 (default from config)
dev-backend:
	cd backend && python main.py

# Flutter web dev server on :3000, pointing at backend :3300.
# AUTH0_* values must match your Auth0 Dashboard + backend .env.
# AUTH0_AUDIENCE must be the API identifier (e.g. https://debt-display-api);
# without it Auth0 issues opaque tokens that the backend cannot verify.
dev-flutter:
	flutter run -d chrome --web-port=3000 \
		--dart-define=BACKEND_URL=http://localhost:3300 \
		--dart-define=FRONTEND_URL=http://localhost:3000 \
		--dart-define=AUTH0_DOMAIN=$(AUTH0_DOMAIN) \
		--dart-define=AUTH0_CLIENT_ID=$(AUTH0_CLIENT_ID) \
		--dart-define=AUTH0_AUDIENCE=$(AUTH0_AUDIENCE)
