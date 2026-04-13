.PHONY: proto

proto:
	python -m grpc_tools.protoc -I proto/ --python_out=backend/proto/ proto/auth.proto
	protoc -I proto/ --dart_out=lib/generated/ proto/auth.proto
