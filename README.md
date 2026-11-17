# E Track (Flutter)

Offline-first expense **and task** tracker client. The app writes locally first
(Hive) and is designed to sync with the E Track Deno API when connectivity is
available.

> **Platform focus:** Android only. Other platform folders are intentionally
> left untouched for now.

> **Status:** architecture, theming, routing, DI, storage and state scaffolding
> are in place. Sign-in/sign-up, session restore, the global search client and
> the dashboard home screen are implemented. Expense/task list/add UIs are still
> stubbed.

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
| HTTP client | `http` 1 |

## Getting started

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The app points to the deployed API by default:
`https://vnr-deno.itssagarbro.deno.net/`. `ApiClient` appends `/api`, so pass
the host root when overriding it for local testing:

```bash
flutter run --dart-define=ETRACK_API_BASE_URL=http://192.168.1.10:8000
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
    network/                      # ApiClient, TokenProvider
    storage/                      # HiveService, SecureStorageService
    theme/app_theme.dart          # minimal light + dark Material 3 themes
  features/
    auth/                         # login flow (data / domain / presentation)
    expenses/                     # entity, local data source, repository, placeholder page
    tasks/                        # entity, local data source, repository, placeholder page
    home/                         # dashboard: budget, summary bloc, charts, tabs
    search/                       # global search client (API -> domain)
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for layer rules and the offline sync plan.

## What works today

- App boots with Hive boxes opened and dependencies registered.
- Minimal clean light/dark UI driven by `AppTheme`, following system brightness.
- `go_router` routes for splash, login, home, expenses and tasks, with auth-aware
  redirects so a successful sign-in lands on the home page.
- `AuthBloc` handles sign-in/sign-up and sign-out. `AuthRemoteDataSource` calls
  `POST /api/auth/login`, `POST /api/auth/register` and `GET /api/auth/me`; the
  token is kept in `flutter_secure_storage` and API error messages reach the UI.
- Expense and task entities with Hive-backed local data sources are ready for
  the feature UIs. Tasks support categories: Personal, Work, Travel, Food, Other.
- Dashboard home screen with an editable total budget (default ₹50,000, saved in
  Hive), total spend, remaining balance, a progress bar and a category donut
  drawn with `CustomPainter`. Recent tasks and expenses appear in tabs.
- Global search client calls `GET /api/search` with the stored bearer token and
  parses combined expense/task results.

## Next phase

1. Add token refresh and automatic retry for expired tokens.
2. Build the expense list/add flow on top of `ExpenseRepository`; the dashboard
   already reads those records, so new expenses appear after refresh.
3. Build the task list/add flow on top of `TaskRepository`.
4. Switch the dashboard totals to the sync API once expense CRUD lands.
5. Wire `SearchRepository` into a search UI with a `SearchBloc`.
6. Add the outbox sync worker and conflict handling.

## Related documents

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [AGENTS.md](AGENTS.md)
- [GEMINI.md](GEMINI.md)
