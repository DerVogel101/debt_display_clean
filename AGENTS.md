# AGENTS.md

## Environment Notes

This project runs in a Windows environment with PowerShell.

## Protobuf Generation

To regenerate protobuf files successfully:

1. Run commands from the project root.
2. If sandboxed execution fails silently, request elevated approval for `protoc`.
3. Use these commands:

```powershell
protoc -I proto/ --dart_out=lib/generated/ proto/auth.proto
protoc -I proto/ --python_out=backend/proto/ proto/auth.proto
```

Notes:

- `protoc` must be available on `PATH`.
- `protoc-gen-dart` must be available on `PATH`.
- In this repo, elevated execution may be required even when the command itself is correct.

## Python Command Rules

When running Python commands for this project:

- Prefer activating the virtual environment first, or
- Use `uv run ...` instead of bare `python ...`

Examples:

```powershell
.venv\Scripts\Activate.ps1
python main.py
```

or

```powershell
uv run python main.py
```

Do not assume global Python packages are installed. If a Python command depends on project packages, use the venv or `uv run`.
