# E Track (Flutter)

Offline-first expense tracker client. The app writes locally first (Hive) and is
designed to sync with the E Track Deno API when connectivity is available.

> **Status:** foundation phase. Architecture, theming, routing, DI, storage and
> auth state scaffolding are in place. API calls and expense UI are intentionally
> stubbed for the next phase.

## Stack

| Concern | Choice |
| --- | --- |
| Framework | Flutter 3.47 / Dart 3.13 |
| State management | `flutter_bloc` / `bloc` 9 |
| Dependency injection | `get_it` 9 |
| Routing | `go_router` 18 |
| Secure token storage | `flutter_secure_storage` 11 |
| Local database | `hive` 2 + `hive_flutter` 1 |
| Code generation | `build_runner` + `hive_generator` (for future typed adapters) |
| Dates/formatting | `intl` |
| IDs | `uuid` |

## Getting started

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Point the app at a different API host (Android emulator default is
`http://10.0.2.2:8000/api`):

```bash
flutter run --dart-define=ETRACK_API_BASE_URL=http://192.168.1.10:8000/api
```

When typed Hive adapters are added, regenerate them with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Current structure

```text
lib/
  main.dart                       # Hive init + DI init + runApp
  app/
    app.dart                      # ETrackApp: BlocProvider, themes, router
    router/app_router.dart        # go_router route table
    di/injection.dart             # get_it registrations
  core/
    constants/                    # app name, API base URL, storage keys, routes
    error/failures.dart           # domain failures
    storage/                      # HiveService, SecureStorageService
    theme/app_theme.dart          # minimal light + dark Material 3 themes
  features/
    auth/                         # login flow (data / domain / presentation)
    expenses/                     # expense entity, Hive data source, placeholder page
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for layer rules and the offline sync plan.

## What works today

- App boots with Hive boxes opened and dependencies registered.
- Minimal clean light/dark UI driven by `AppTheme`, following system brightness.
- `go_router` routes for splash, login and home/expenses.
- `AuthBloc` checks a stored token, handles sign-in/sign-out states and reports
  errors. The remote data source is a documented stub until the API phase.
- Expense entity and Hive-backed local data source are ready for the feature UI.

## Next phase

1. Implement `AuthRemoteDataSource` against `POST /api/auth/login` and
   `GET /api/auth/me` using the bearer token.
2. Add the HTTP client, token refresh and auth-aware router redirects.
3. Build the expense list/add flow on top of `ExpenseLocalDataSource`.
4. Add the outbox sync worker and conflict handling.

## Related documents

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [AGENTS.md](AGENTS.md)
- [GEMINI.md](GEMINI.md)
