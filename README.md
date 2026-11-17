# E Track (Flutter)

Offline-first expense **and task** tracker client. The app writes locally first
(Hive) and is designed to sync with the E Track Deno API when connectivity is
available.

> **Platform focus:** Android only. Other platform folders are intentionally
> left untouched for now.

> **Status:** architecture, theming, routing, DI, storage and state scaffolding
> are in place. Sign-in/sign-up, session restore, the API-backed search page, the
> dashboard, bottom navigation, profile page and expense/task add flows are
> implemented. Records are stored locally first in Hive, queued in an outbox and
> synced to the Deno API when online. Edit sheets, swipe-to-delete with an Undo
> snackbar, connectivity-driven auto sync and a live sync-status badge are built.

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
| Network monitoring | `connectivity_plus` 7 |

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
    router/app_router.dart        # go_router route table + stateful shell
    navigation/                   # bottom navigation shell
  core/
    di/injection.dart             # get_it registrations
    auth/user_id_provider.dart    # active account id for per-user Hive keys
    constants/                    # app name, API base URL, storage keys, routes
    error/failures.dart           # domain failures
    network/                      # ApiClient, TokenProvider, ConnectivityService
    storage/                      # HiveService, SecureStorageService
    sync/                         # outbox, cursors, SyncCoordinator, AutoSyncManager,
                                  # SyncStatusStore + home-header badge
    theme/app_theme.dart          # minimal light + dark Material 3 themes
  features/
    auth/                         # login flow (data / domain / presentation)
    expenses/                     # entity, local + remote data sources, repository, list + add/edit sheet
    tasks/                        # entity, local + remote data sources, repository, list + add/edit sheet
    home/                         # dashboard: budget, summary bloc, charts, tabs
    profile/                      # profile page with sign-out confirmation
    search/                       # global search client, bloc and search page
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for layer rules and the offline sync plan.

## What works today

- App boots with Hive boxes opened and dependencies registered.
- Minimal clean light/dark UI driven by `AppTheme`, following system brightness.
- `go_router` stateful shell with Home, Search and Profile tabs; expenses and
  tasks stay nested under Home so the bottom navigation remains visible.
  Auth-aware redirects send a successful sign-in to the home page.
- `AuthBloc` handles sign-in/sign-up and sign-out. `AuthRemoteDataSource` calls
  `POST /api/auth/login`, `POST /api/auth/register` and `GET /api/auth/me`; the
  token is kept in `flutter_secure_storage` and API error messages reach the UI.
- Expense and task entities with Hive-backed local data sources, namespaced by
  the signed-in user id. Add/edit sheets save records locally; both list pages
  show records, refresh the dashboard automatically, open an edit sheet from the
  pencil icon, and support swipe-to-delete with an Undo snackbar. Tasks support
  categories: Personal, Work, Travel, Food, Other.
- Offline-first sync: every local write is queued in `etrack_pending_sync`.
  `SyncCoordinator` drains the outbox to the API, then pulls changes using
  per-entity `updatedAfter` cursors. It runs on sign-in, on app resume, on
  reconnect, on pull-to-refresh and from the sync button in each list app bar.
  Local edits win until acknowledged; server tombstones remove only synced local
  records.
- `connectivity_plus` drives `AutoSyncManager`: losing the network flips the
  badge to Offline without any failed request, and coming back online starts a
  sync automatically. The dashboard header badge shows syncing/pending/offline/
  up-to-date state and the number of queued changes; tapping it syncs on demand.
- Dashboard home screen with an editable total budget (default ₹50,000, saved in
  Hive), total spend, remaining balance, a progress bar and a category donut
  drawn with `CustomPainter`. Recent tasks and expenses appear in tabs with add
  and "See all" actions; add opens a working sheet and pull down to refresh.
- Search tab runs `GET /api/search` through `SearchRepository`/`SearchBloc` and
  lists combined expense/task results.
- Profile tab shows the signed-in user's name and email with a placeholder
  avatar, links to expenses and tasks, and a sign-out button with a
  confirmation dialog.

## Next phase

1. Add token refresh and automatic retry for expired tokens.
2. Add an OS-level background sync trigger for large queues while the app is closed.
3. Batch outbox operations into a single API call for large offline queues.
4. Surface per-record sync status (pending/conflict indicators) in list items.

## Related documents

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [AGENTS.md](AGENTS.md)
- [GEMINI.md](GEMINI.md)
