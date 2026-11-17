# E Track Flutter Architecture

Clean architecture with a `core/` folder for cross-cutting concerns and
`features/` for business capabilities — auth, expenses, tasks, home dashboard and
search. Android is the only actively supported platform.

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
│   ├── navigation/              # bottom navigation shell
│   │   └── scaffold_with_nav_bar.dart
│   └── router/app_router.dart   # go_router route table + stateful shell
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
    │   ├── data/                # local data source + repository impl
    │   ├── domain/              # Expense entity + ExpenseRepository
    │   └── presentation/pages/expenses_page.dart
    ├── tasks/
    │   ├── data/                # local data source + repository impl
    │   ├── domain/              # TaskItem entity + TaskRepository
    │   └── presentation/pages/tasks_page.dart
    ├── home/
    │   ├── data/                # budget local data source + repository impl
    │   ├── domain/              # DashboardSummary, BudgetRepository
    │   └── presentation/        # DashboardBloc, HomePage, custom painters
    ├── profile/
    │   └── presentation/        # ProfilePage with sign-out confirmation
    └── search/
        ├── data/                # remote data source + repository impl
        ├── domain/              # SearchResult entity + SearchRepository
        └── presentation/        # SearchBloc + SearchPage
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
The three main tabs are a `StatefulShellRoute.indexedStack` in
`app_router.dart`. `ScaffoldWithNavBar` renders a `NavigationBar` and calls
`goBranch(index)` so each tab keeps its own navigator and scroll state. Home,
Search and Profile are separate branches; `/home/expenses` and `/home/tasks` are
nested under Home so the bottom navigation stays visible on those pages. Splash
and login remain outside the shell.

Auth navigation is owned by `authRedirect()`: successful sign-in moves splash
and login to the home dashboard, sign-out from Profile returns to login, and
unauthenticated users are redirected to login. `ETrackApp` mirrors `AuthBloc`
status into a `ValueNotifier` used as GoRouter's `refreshListenable`; pages do
not listen to `AuthBloc` for navigation.

## Storage

| Data | Storage | Access |
| --- | --- | --- |
| Access/refresh tokens | `flutter_secure_storage` | `SecureStorageService` |
| Expenses | Hive box `etrack_expenses` | `ExpenseLocalDataSource` |
| Tasks | Hive box `etrack_tasks` | `TaskLocalDataSource` |
| Offline sync outbox | Hive box `etrack_pending_sync` | `HiveService.pendingSyncBox` |
| Total budget | Hive box `etrack_settings` (`total_budget`) | `BudgetLocalDataSource` / `BudgetRepository` |
| Other settings | Hive box `etrack_settings` | `HiveService.settingsBox` |

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

1. User signs in or creates an account; `AuthRemoteDataSource` posts credentials
   to `POST /api/auth/login` or `POST /api/auth/register`.
2. API returns `{ token, user }`; `AuthRepositoryImpl` stores the token with
   `SecureStorageService` and maps the user into the domain entity.
3. `AuthBloc` emits `authenticated` and routing moves to the home page. On a
   server error it shows the API message (for example, invalid credentials).
4. On startup, `AuthCheckRequested` reads the token and validates it with
   `GET /api/auth/me`.
5. A failed validation or `401` response clears the stored token and emits
   `unauthenticated`.
6. `ETrackApp` mirrors the auth status into a `ValueNotifier` used as GoRouter's
   `refreshListenable`. `authRedirect()` in `lib/app/router/` decides whether to
   send the user home, to login, or leave the current route alone. Pages do not
   listen to `AuthBloc` for navigation.

## Global search

`GET /api/search?q=<text>&limit=<1..50>` returns expenses and tasks for the
authenticated user, merged newest-first. On the client:

- `ApiClient` (core/network) builds the URL and maps HTTP failures to
  `Failure` values.
- `TokenProvider` supplies the bearer token without exposing the storage plugin
  to features.
- `SearchRemoteDataSourceImpl` calls `/search` and parses the response.
- `SearchRepository` is the only API the presentation layer should call.

`SearchBloc` turns a submitted query into loading/ready/failure states, and
`SearchPage` renders the results with expense/task icons. Search results remain
read-only from MongoDB for now; local caching comes with sync.

## Dashboard

The `/home` dashboard is built from local data because expense/task CRUD
endpoints still return `501` on the API:

- `DashboardBloc` depends only on domain repositories: `ExpenseRepository`,
  `TaskRepository` and `BudgetRepository`.
- `DashboardSummary` holds the budget, total spend, remaining balance, per-category
  spend shares and the five most recent expenses/tasks.
- The budget defaults to ₹50,000, is edited from the summary card and is saved
  through `BudgetRepository` (Hive settings box).
- `BudgetProgressBar` and `CategoryDonutChart` are `CustomPainter` widgets, so no
  chart package is required. Their accent colors come from `AppTheme.chartPalette`.
- Recent tasks and expenses are shown in tabs. Each tab has an add action and a
  "See all" link into the full page, and the whole dashboard is wrapped in a
  `RefreshIndicator` that replays `DashboardStarted`.
- The top bar intentionally has no refresh or sign-out buttons; sign-out lives
  on Profile behind a confirmation dialog.

When the sync API lands, only the repository implementations need to change;
the bloc and widgets stay the same.

## Profile

`ProfilePage` reads the current `AppUser` from `AuthBloc` and shows the display
name, email and a placeholder avatar. Expenses and Tasks buttons navigate with
`context.go(AppRoutes.x)`. The Log out button opens a confirmation dialog and
only dispatches `AuthSignOutRequested` after the user confirms; `authRedirect()`
then moves to login.

## Theming

`AppTheme` in `lib/core/theme/app_theme.dart` builds light and dark `ThemeData`
from one seed color. `ETrackApp` supplies both to `MaterialApp.router` and
currently follows `ThemeMode.system`. Component theming (inputs, cards,
buttons, app bars) is centralized there — pages should not hard-code colors.

## Testing

- Unit tests: blocs and repositories with mocked domain repositories/data sources
  (`AuthBloc`, dashboard totals/budget persistence and `SearchBloc`).
- Widget tests: pages with mocked/replaced blocs, including the dashboard summary,
  recent-activity actions, search results, profile sign-out and bottom navigation
  branch switching.
- Keep tests free of real plugin calls; inject `SecureStorageService` and Hive
  boxes where needed.

Run:

```bash
flutter analyze
flutter test
```
