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
│   ├── app.dart                 # ETrackApp (providers, auth/sync listeners, MaterialApp.router)
│   ├── navigation/              # bottom navigation shell
│   │   └── scaffold_with_nav_bar.dart
│   └── router/app_router.dart   # go_router route table + stateful shell
├── core/
│   ├── auth/user_id_provider.dart  # active account id for per-user Hive keys
│   ├── constants/               # AppConstants, AppRoutes
│   ├── di/injection.dart        # get_it registrations
│   ├── error/failures.dart      # typed failures
│   ├── network/
│   │   ├── api_client.dart      # JSON GET/PUT/POST/PATCH/DELETE wrapper over http
│   │   ├── token_provider.dart  # bearer token access abstraction
│   │   └── connectivity_service.dart  # ConnectivityService over connectivity_plus
│   ├── storage/
│   │   ├── hive_service.dart    # box lifecycle + accessors
│   │   └── secure_storage_service.dart
│   ├── sync/
│   │   ├── sync_outbox.dart        # outbox interface + PendingSyncOperation
│   │   ├── hive_sync_outbox.dart   # Hive-backed outbox
│   │   ├── sync_cursor_store.dart  # per-user, per-entity updatedAfter cursors
│   │   ├── sync_coordinator.dart   # SyncService: drain outbox, then pull remote
│   │   ├── sync_status.dart        # SyncResult, SyncPhase, SyncStatusStore
│   │   ├── sync_status_badge.dart  # tappable home-header status indicator
│   │   ├── auto_sync_manager.dart  # runs sync on reconnect, tracks online state
│   │   └── sync_feedback.dart      # user-facing sync result + badge messages
│   └── theme/app_theme.dart     # light + dark themes
└── features/
    ├── auth/
    │   ├── data/                # datasources, models, repository impl
    │   ├── domain/              # AppUser, AuthRepository
    │   └── presentation/        # AuthBloc, pages
    ├── expenses/
    │   ├── data/                # local + remote data sources, repository impl
    │   ├── domain/              # Expense entity + ExpenseRepository
    │   └── presentation/        # list page + add/edit sheet
    ├── tasks/
    │   ├── data/                # local + remote data sources, repository impl
    │   ├── domain/              # TaskItem entity + TaskRepository
    │   └── presentation/        # list page + add/edit sheet
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
- `ExpenseRepository` and `TaskRepository` expose a `changes` stream. Local writes
  emit on it, so list pages and the dashboard bloc refresh without pages having
  to know about each other.
- Provide blocs once near the root with `BlocProvider` and domain repositories
  with `RepositoryProvider`; resolve the instances through `getIt`. Add
  `BlocListener` for one-off effects like navigation and snackbars.

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
| Offline sync outbox | Hive box `etrack_pending_sync` | `HiveSyncOutbox` |
| Sync cursors | Hive box `etrack_settings` (`last_sync_<user>_<scope>`) | `HiveSyncCursorStore` |
| Total budget | Hive box `etrack_settings` (`total_budget`) | `BudgetLocalDataSource` / `BudgetRepository` |
| Other settings | Hive box `etrack_settings` | `HiveService.settingsBox` |

Passwords are never stored locally. Hive initialization happens once in
`main()` through `HiveService.init()` before `getIt` registrations that depend
on boxes. Expense/task record keys are prefixed with `<userId>::` so accounts
on the same device never see each other's data; the outbox and cursors are
scoped to the active `UserIdProvider` value, which `ETrackApp` updates from
`AuthBloc`.

## Offline-first sync (implemented)

1. Every expense/task create, edit or delete writes to Hive first and marks the
   record `isSynced = false`, then enqueues an operation in the outbox
   (`etrack_pending_sync`). The UI reads only local state and never blocks on
   the network.
2. `SyncCoordinator` (`SyncService`) drains the outbox in order, attaching the
   bearer token from `TokenProvider`. Upserts `PUT /api/(expenses|tasks)/:id`
   with the client-generated UUID; deletes call `DELETE /:id`.
3. After a successful upload, the service marks the local record `isSynced =
   true` with the server `updatedAt` and removes the outbox operation. A failure
   (offline/`Failure`) leaves the operation queued for the next run.
4. It then pulls remote changes with `GET /api/(expenses|tasks)?updatedAfter=
   <cursor>&limit=200`, using per-entity cursors from `SyncCursorStore`. Server
   records are applied without re-queueing; tombstones (`deletedAt`) remove the
   local copy.
5. Conflicts: local edits with a pending outbox operation or `isSynced == false`
   always win over incoming server records. Only synced local records can be
   removed by a server tombstone. Undo re-inserts a deleted record and re-queues
   an upsert, which resurrects it server-side (upserts clear `deletedAt`).
6. Sync runs on sign-in, on app resume (`WidgetsBindingObserver`), on reconnect
   (see below), on pull-to-refresh and from the sync icon in the list app bars. A
   `_running` guard prevents overlapping runs.

Remote data sources (`ExpenseRemoteDataSource`, `TaskRemoteDataSource`) map the
API wire format (`description` for task notes) to domain entities and are the
only feature code that touches `ApiClient`.

## Connectivity and automatic sync

`ConnectivityService` wraps `connectivity_plus` and emits a simple `bool`
reachability signal (a non-empty result set without `ConnectivityResult.none`).
`AutoSyncManager`, started/stopped by `ETrackApp`, listens to that stream:

- Losing connectivity sets `SyncStatusStore.online = false` immediately. No API
  call is attempted; local writes keep queueing in the outbox.
- A transition back to online (or the first online reading at startup) calls
  `SyncService.run()`, so pending edits upload without user interaction.
- `SyncCoordinator` also writes to `SyncStatusStore` on every run (syncing →
  synced/offline/error) and whenever the outbox changes (pending count).

`SyncStatusBadge` in the dashboard app bar is a `ValueListenableBuilder` over the
store. It shows a spinner while syncing, a queued-count badge with a cloud-upload
icon when changes are pending, a cloud-off icon when offline, and a cloud-done
icon when everything is up to date. Tapping it triggers a manual sync. Android
gets the `ACCESS_NETWORK_STATE` permission from the plugin's manifest — no manual
Android edits are needed.

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
`SearchPage` renders the results with expense/task icons. Search reads the API
directly (it excludes soft-deleted server records); local caching of search hits
is not implemented yet.

## Dashboard

The `/home` dashboard is built from local Hive data (which the sync layer keeps
up to date), so it renders instantly online or offline:

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
- The top bar hosts `SyncStatusBadge` (connectivity + sync state, tap to sync);
  sign-out lives on Profile behind a confirmation dialog.

The bloc depends only on domain repositories, so it and the widgets stayed the
same when CRUD and sync landed — only the repository implementations changed.

## Profile

`ProfilePage` reads the current `AppUser` from `AuthBloc` and shows the display
name, email and a placeholder avatar. Expenses and Tasks buttons navigate with
`context.go(AppRoutes.x)`. The Log out button opens a confirmation dialog and
only dispatches `AuthSignOutRequested` after the user confirms; `authRedirect()`
then moves to login.

## Expenses and tasks

Both list pages read their records from the injected domain repository and
subscribe to `changes`. Their floating action buttons open modal sheets; a
pencil icon opens the same sheet pre-filled for editing:

- Expense sheet: title, amount, category and date; saves an `Expense` with a
  generated UUID through `ExpenseRepository`. In edit mode it reuses the record
  id and sync state.
- Task sheet: title, category, optional note and optional due date; saves a
  `TaskItem` through `TaskRepository`, again reusing the id when editing.
- The Home dashboard's add buttons open the same sheets directly; its "See all"
  links navigate to the full list pages.
- Swiping a row left deletes it locally and shows a SnackBar with an **Undo**
  action; Undo re-inserts the record and re-queues an upsert.
- Each app bar has a sync icon and pull-to-refresh runs a sync; results are
  shown in a SnackBar via `syncMessage()`.
- Saving emits a repository change, so the current list and the dashboard both
  update immediately, even while offline.

## Theming

`AppTheme` in `lib/core/theme/app_theme.dart` builds light and dark `ThemeData`
from one seed color. `ETrackApp` supplies both to `MaterialApp.router` and
currently follows `ThemeMode.system`. Component theming (inputs, cards,
buttons, app bars) is centralized there — pages should not hard-code colors.

## Testing

- Unit tests: blocs and repositories with mocked domain repositories/data sources
  (`AuthBloc`, dashboard totals/budget persistence and `SearchBloc`).
- Widget tests: pages with mocked/replaced blocs and repositories, including the
  dashboard summary, expense/task add sheets, search results, profile sign-out
  and bottom navigation branch switching.
- Keep tests free of real plugin calls; inject `SecureStorageService` and Hive
  boxes where needed.

Run:

```bash
flutter analyze
flutter test
```
