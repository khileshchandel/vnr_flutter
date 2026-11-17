# AGENTS.md — E Track Flutter

Instructions for AI agents and contributors working in this repository.

## Project

- App name: **E Track** (offline-first expense **and task** tracker).
- Pub package: `e_track`. Do not rename folders; paths are fixed by the project
  owner (`D:\Sagar\Flutter\vnr_flutter`).
- Platform focus: **Android only**. From now on, do not change anything under
  `ios/`, `web/`, `macos/`, `windows/` or `linux/` unless explicitly asked.
- Stack: Flutter 3.47 / Dart 3.13, flutter_bloc 9, get_it 9, go_router 18,
  flutter_secure_storage 11, hive 2 + hive_flutter 1, intl, uuid, http 1.
- Backend lives separately at `D:\Sagar\Deno\vnr_deno` (Hono + Deno + Mongoose).

## Current phase

Storage, DI, routing, theming and state scaffolding exist for both expenses and
tasks. Sign-in and sign-up call the real API through `AuthRemoteDataSource`; the
`StatefulShellRoute` bottom tabs are Home, Search and Profile; `SearchPage` uses
`SearchRepository` through `SearchBloc`; the `/home` dashboard shows an editable
budget, spend summary, category donut and recent tasks/expenses with pull-to-refresh,
add and "See all" actions. Profile shows the signed-in user and signs out after
confirmation. Full expense/task list/add flows are not built yet. Do not build
them unless asked.

## Rules

1. Follow clean architecture: `domain` has no Flutter/HTTP/Hive imports; `data`
   implements domain interfaces; `presentation` depends on domain only.
2. Put shared, non-feature code in `lib/core/`. Feature code stays under
   `lib/features/<feature>/{data,domain,presentation}`.
3. Register dependencies in `lib/core/di/injection.dart` via `getIt`. Never call
   `GetIt.instance` directly from widgets.
4. All navigation goes through `appRouter` and `AppRoutes` constants.
5. All colors/typography come from `AppTheme`. Do not hard-code theme values in
   pages.
6. Tokens go through `SecureStorageService`; never store passwords or tokens in
   Hive, shared preferences, logs or error messages.
7. Open Hive boxes only in `HiveService.init()` and access them via
   `HiveService` accessors or an injected data source.
8. Keep widgets dumb: snackbars belong in `BlocListener`. Auth navigation is
   owned by `authRedirect()` in `lib/app/router/`; pages must not navigate on
   `AuthBloc` state changes.
9. New typed Hive models require an adapter registered in `HiveService` and
   generated with `dart run build_runner build --delete-conflicting-outputs`.
10. Update `README.md` and `ARCHITECTURE.md` when structure or behavior changes.
    `GEMINI.md` references this file; keep it aligned.
11. Android is the only target platform for active work. Do not edit `ios/`,
    `web/`, `macos/`, `windows/` or `linux/` from now on unless the user asks.
    Keep changes to `lib/`, `test/`, `android/` and the Markdown docs.
12. Global search goes through `SearchRepository`. Widgets must not call
    `ApiClient` directly; tokens come only from `TokenProvider`.

## Commands

```bash
flutter pub get
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs   # when adapters change
flutter run --dart-define=ETRACK_API_BASE_URL=http://192.168.1.10:8000
```

## Style

- Dart 3 syntax (`sealed`, `final class`, `abstract interface class`) is fine.
- Use relative imports within a feature, `package:e_track/...` from `app/` and
  `core/` when clearer; stay consistent with nearby files.
- Keep files focused; prefer small, named private methods over deep nesting.
