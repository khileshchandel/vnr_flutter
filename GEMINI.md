# GEMINI.md — E Track Flutter

This project is governed by [AGENTS.md](AGENTS.md). Read it fully before making
changes; it is the source of truth for stack, structure and conventions.

## Quick reference

- Package: `e_track`. App name: **E Track** (expense + task tracker).
- Platform focus: **Android only**. Do not change `ios/`, `web/`, `macos/`,
  `windows/` or `linux/` unless explicitly asked.
- Architecture: clean architecture with `lib/core/` and
  `lib/features/<feature>/{data,domain,presentation}`.
- State: `flutter_bloc`; DI: `get_it` (`lib/core/di/injection.dart`);
  routing: `go_router` (`lib/app/router/app_router.dart`) with a stateful
  bottom-nav shell (`lib/app/navigation/`);
  theming: `lib/core/theme/app_theme.dart` (light + dark);
  storage: Hive via `lib/core/storage/hive_service.dart`, tokens via
  `lib/core/storage/secure_storage_service.dart`;
  HTTP: `lib/core/network/api_client.dart`, global search via
  `lib/features/search/`;
  offline sync: `lib/core/sync/` (outbox, cursors, `SyncCoordinator`), per-user
  Hive keys via `lib/core/auth/user_id_provider.dart`.
- Current scope: auth and the API-backed Search tab call the real API; the home
  dashboard renders local expense/task summaries with an editable budget and
  pull-to-refresh; bottom tabs are Home, Search and Profile (with confirmed
  sign-out). Expense/task add + edit sheets, swipe-to-delete with Undo, and an
  outbox-based sync to the Deno API (auto on resume + manual) all work.

## Expectations

- Preserve the layer boundaries described in `ARCHITECTURE.md`.
- Do not commit secrets, `.env` files or generated build output.
- Run `flutter analyze` and `flutter test` after changes.
- Update `README.md` / `ARCHITECTURE.md` alongside structural changes.
