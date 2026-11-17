# GEMINI.md — E Track Flutter

This project is governed by [AGENTS.md](AGENTS.md). Read it fully before making
changes; it is the source of truth for stack, structure and conventions.

## Quick reference

- Package: `e_track`. App name: **E Track**.
- Architecture: clean architecture with `lib/core/` and
  `lib/features/<feature>/{data,domain,presentation}`.
- State: `flutter_bloc`; DI: `get_it` (`lib/core/di/injection.dart`);
  routing: `go_router` (`lib/app/router/app_router.dart`);
  theming: `lib/core/theme/app_theme.dart` (light + dark);
  storage: Hive via `lib/core/storage/hive_service.dart`, tokens via
  `lib/core/storage/secure_storage_service.dart`.
- Current scope: foundation phase only; API calls and expense UI are stubbed.

## Expectations

- Preserve the layer boundaries described in `ARCHITECTURE.md`.
- Do not commit secrets, `.env` files or generated build output.
- Run `flutter analyze` and `flutter test` after changes.
- Update `README.md` / `ARCHITECTURE.md` alongside structural changes.
