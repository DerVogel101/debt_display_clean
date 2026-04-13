.PHONY: proto dev-backend dev-flutter

# ── Protobuf codegen ──────────────────────────────────────────────────────────
proto:
	python -m grpc_tools.protoc -I proto/ --python_out=backend/proto/ proto/auth.proto
	protoc -I proto/ --dart_out=lib/generated/ proto/auth.proto

# ── Dev servers ───────────────────────────────────────────────────────────────
# Backend on :3300 (default from config)
dev-backend:
	cd backend && python main.py

# Flutter web dev server on :3000, pointing at backend :3300
# BACKEND_URL and FRONTEND_URL are passed as Dart compile-time constants.
dev-flutter:
	flutter run -d chrome --web-port=3000 \
		--dart-define=BACKEND_URL=http://localhost:3300 \
		--dart-define=FRONTEND_URL=http://localhost:3000
