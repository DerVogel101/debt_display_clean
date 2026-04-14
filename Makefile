.PHONY: proto dev-backend dev-flutter

# ── Protobuf codegen ──────────────────────────────────────────────────────────
proto:
	protoc -I proto/ --python_out=backend/proto/ --pyi_out=backend/proto/ --plugin=protoc-gen-dart=C:/Users/janir/AppData/Local/Pub/Cache/bin/protoc-gen-dart.bat --dart_out=lib/generated/ proto/auth.proto proto/debt.proto

# ── Dev servers ───────────────────────────────────────────────────────────────
# Backend on :3300 (default from config)
dev-backend:
	cd backend && python main.py

# Flutter web dev server on :3000, pointing at backend :3300.
# Frontend config now comes from assets/env/app.env.
dev-flutter:
	flutter run -d chrome --web-port=3000
