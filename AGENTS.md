# AGENTS.md

## Environment Notes

This project runs in a Windows environment with PowerShell.

## Dart / Flutter Commands

When running `dart` or `flutter` commands in this repo:

1. Start from project root.
2. Expect sandboxed execution to fail or hang.
3. Always request elevated approval for `dart ...` and `flutter ...` commands.
4. Do not run them in the sandbox.

Examples:

```powershell
dart analyze
flutter analyze
flutter test
```

## Protobuf Generation

When running `protoc` commands in this repo:

1. Start from project root.
2. Always request elevated approval for `protoc ...` commands.
3. Do not run them in the sandbox.

To regenerate protobuf files successfully:

1. Run commands from the project root.
2. If sandboxed execution fails silently, request elevated approval for `protoc`.
3. Use these commands:

```powershell
protoc -I proto/ --python_out=backend/proto/ --pyi_out=backend/proto/ --plugin=protoc-gen-dart=C:/Users/janir/AppData/Local/Pub/Cache/bin/protoc-gen-dart.bat --dart_out=lib/generated/ proto/auth.proto proto/debt.proto
```

Notes:

- `protoc` must be available on `PATH`.
- `protoc-gen-dart` must be available on `PATH`.
- Generate Python `.pyi` stubs with `--pyi_out=backend/proto/` to help IDE static analysis resolve protobuf message classes.
- In this repo, elevated execution may be required even when the command itself is correct.

## Python Command Rules

When running Python commands for this project:

- Prefer activating the virtual environment first, or
- Use `uv run ...` instead of bare `python ...`

Examples:

```powershell
.venv\Scripts\Activate.ps1
python -m backend.main
```

or

```powershell
uv run python -m backend.main
```

Do not assume global Python packages are installed. If a Python command depends on project packages, use the venv or `uv run`.

## Flutter State Management Rules

For Flutter UI state in this repo:

1. Use `provider` with `MultiProvider` at the app root for app-wide state.
2. Split unrelated concerns into distinct `ChangeNotifier` app states instead of growing one global state object.
3. Prefer `context.select`, `Selector`, and `Consumer.child` to listen to specific attributes and minimize unnecessary rebuilds.
4. Do not watch entire notifiers from broad layout widgets unless a full subtree rebuild is intentional.
5. Reserve widget-local `setState` for ephemeral local UI concerns only.

## AGENTS.md Maintenance

If you notice repo-specific commands, pitfalls, conventions, or workflows that would likely help future agents, suggest adding them to this `AGENTS.md` file when appropriate.
