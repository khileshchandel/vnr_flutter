# E Track Flutter Architecture

Clean architecture with a `core/` folder for cross-cutting concerns and
`features/` for business capabilities — currently expenses and tasks. Android is
the only actively supported platform.

## Dependency rule

```text
presentation  ->  domain  <-  data
     |              ^
     +--- core -----+
```

- **domain** — entities, repository interfaces, use cases. No Flutter, Hive or
  HTTP imports.
- **data** — repository implementations, models, remote/local data sources.
  Maps DTOs to domain entities and exceptions to `Failure` values.
- **presentation** — pages, widgets, blocs. Depends on domain abstractions only.
- **core** — constants, theme, storage services, DI, router-level helpers.
  Shared code that is not a business feature.

Never import from another feature's `data` layer. Cross-feature communication
goes through domain interfaces or shared core services.

## Folder layout

```text
lib/
├── app/                         # Application wiring
│   ├── app.dart                 # ETrackApp (MultiBlocProvider + MaterialApp.router)
│   ├── di/injection.dart        # get_it registrations
│   └── router/app_router.dart   # go_router route table
├── core/
│   ├── constants/               # AppConstants, AppRoutes
│   ├── error/failures.dart      # typed failures
│   ├── network/
│   │   ├── api_client.dart      # JSON GET wrapper over http
│   │   └── token_provider.dart  # bearer token access abstraction
│   ├── storage/
│   │   ├── hive_service.dart    # box lifecycle + accessors
│   │   └── secure_storage_service.dart
│   └── theme/app_theme.dart     # light + dark themes
└── features/
    ├── auth/
    │   ├── data/                # datasources, models, repository impl
    │   ├── domain/              # AppUser, AuthRepository
    │   └── presentation/        # AuthBloc, pages
    ├── expenses/
    │   ├── data/datasources/expense_local_data_source.dart
    │   ├── domain/entities/expense.dart
    │   └── presentation/pages/expenses_page.dart
    ├── tasks/
    │   ├── data/datasources/task_local_data_source.dart
    │   ├── domain/entities/task_item.dart
    │   └── presentation/pages/tasks_page.dart
    └── search/
        ├── data/                # remote data source + repository impl
        ├── domain/              # SearchResult entity + SearchRepository
        └── presentation/        # search UI/Bloc (next phase)
```

## State management (Bloc)

- One `Bloc` per feature flow, kept in `features/<feature>/presentation/bloc`.
- Events are imperative intents (`AuthSignInRequested`); states are snapshots
  (`AuthStatus`, user, error message).
- Blocs call repository interfaces, never data sources or Hive boxes directly.
- Provide blocs once near the root with `BlocProvider` and resolve them through
  `getIt`. Add `BlocListener` for one-off effects like navigation and snackbars.

## Navigation (go_router)

`appRouter` in `lib/app/router/app_router.dart` is the single route table. Pages
use `context.go(AppRoutes.x)` / `context.push(...)` rather than `Navigator.of`.
Auth-aware redirects will be added once the API login is implemented; until
then `SplashPage` reacts to `AuthBloc` state and routes to login/home.

## Storage

| Data | Storage | Access |
| --- | --- | --- |
| Access/refresh tokens | `flutter_secure_storage` | `SecureStorageService` |
| Expenses | Hive box `etrack_expenses` | `ExpenseLocalDataSource` |
| Tasks | Hive box `etrack_tasks` | `TaskLocalDataSource` |
| Offline sync outbox | Hive box `etrack_pending_sync` | `HiveService.pendingSyncBox` |
| Settings/preferences | Hive box `etrack_settings` | `HiveService.settingsBox` |

Passwords are never stored locally. Hive initialization happens once in
`main()` through `HiveService.init()` before `getIt` registrations that depend
on boxes.

## Offline-first plan

1. Every expense/task create or update writes to Hive first and marks the
   record `isSynced = false`, then appends an operation to the pending sync box.
2. A sync service (next phase) drains the outbox in order when online, attaching
   the bearer token from secure storage.
3. Server responses replace local records and set `isSynced = true`.
4. Conflicts use server timestamps with a deterministic rule: last-write-wins
   for edits, unique client-generated `uuid` IDs for creates (idempotent retry).
5. Failures keep the operation in the outbox with retry/backoff; the UI reads
   only local state, so it never blocks on the network.

## Authentication flow

1. User signs in; `AuthRemoteDataSource` posts credentials to the Deno API.
2. API returns `{ token, user }`; token is stored with `SecureStorageService`.
3. `AuthBloc` emits `authenticated` and routing moves to the home page.
4. On startup, `AuthCheckRequested` reads the token and later validates it with
   `GET /api/auth/me`.
5. `401` responses trigger token cleanup and an `unauthenticated` state.

## Global search

`GET /api/search?q=<text>&limit=<1..50>` returns expenses and tasks for the
authenticated user, merged newest-first. On the client:

- `ApiClient` (core/network) builds the URL and maps HTTP failures to
  `Failure` values.
- `TokenProvider` supplies the bearer token without exposing the storage plugin
  to features.
- `SearchRemoteDataSourceImpl` calls `/search` and parses the response.
- `SearchRepository` is the only API the presentation layer should call.

A `SearchBloc` and search page will be added in the features phase. Search
results remain read-only from MongoDB for now; local caching comes with sync.

## Theming

`AppTheme` in `lib/core/theme/app_theme.dart` builds light and dark `ThemeData`
from one seed color. `ETrackApp` supplies both to `MaterialApp.router` and
currently follows `ThemeMode.system`. Component theming (inputs, cards,
buttons, app bars) is centralized there — pages should not hard-code colors.

## Testing

- Unit tests: blocs and repositories with mocked data sources.
- Widget tests: pages with a mocked/replaced `AuthBloc`, theme assertions.
- Keep tests free of real plugin calls; inject `SecureStorageService` and Hive
  boxes where needed.

Run:

```bash
flutter analyze
flutter test
```
