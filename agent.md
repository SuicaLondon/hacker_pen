# Hacker Pen Agent Guide

## Project

Hacker Pen is a Flutter app for reading Hacker News. The project intentionally does not support Flutter Web; do not recreate or commit a `web/` directory.

## Tech Stack

- Flutter app written in Dart.
- Flutter SDK is pinned with FVM to `3.41.9`; use the `.fvmrc` value as the source of truth when it changes.
- State management uses `flutter_bloc`.
- Hacker News data access uses `http`, repository classes, and `cached_query` for in-memory server-state caching.
- Detail pages can use `webview_flutter` where embedded web content is required.
- AI settings and secrets use `shared_preferences` and `flutter_secure_storage`.
- Supported platform targets are iOS, Android, macOS, Linux, and Windows. Flutter Web is intentionally unsupported.

## Toolchain

Use FVM for every Flutter and Dart command.

Pinned SDK:

```sh
fvm install
fvm flutter --version
```

Common commands:

```sh
fvm flutter pub get
fvm dart format lib test
fvm flutter analyze
fvm flutter test
```

Run targets:

```sh
fvm flutter run -d ios
fvm flutter run -d android
fvm flutter run -d macos
fvm flutter run -d linux
fvm flutter run -d windows
```

Do not use plain `flutter` or `dart` unless diagnosing a local machine issue. The repo is pinned with `.fvmrc` so CI and local development should use the same Flutter version.

## Architecture

Keep source code under `lib/src`.

Current structure:

```text
lib/
  main.dart
  src/
    app.dart
    core/
      api/
      domain/
      theme/
      utils/
    features/
      item_detail/
      items/
```

Guidelines:

- `core/` contains shared app infrastructure, shared Hacker News domain objects, theme, and utilities.
- `features/*` contains feature-specific data, domain, and presentation code.
- Shared domain types such as `HnItem` and `StoryType` belong in `core/domain`, not inside one feature.
- Feature UI should not call HTTP APIs directly. Use repositories and cubits.
- Server-state fetching and caching belongs in `ApiClient`, using `cached_query`. Feature API services should map domain endpoints and decode responses.
- Keep platform folders close to Flutter defaults unless a platform-specific permission, entitlement, signing, or app identity change is required.

## Flutter Style

Prefer current stable Flutter and Dart idioms:

- Use `const` constructors where possible.
- Prefer pattern matching and switch expressions when they make state handling clearer.
- Keep widgets small and private when they are only used by one view.
- Keep async state transitions explicit in cubits.
- Avoid broad refactors when a focused change solves the problem.
- Do not keep reusable parsing/formatting helpers as private widget functions (for example `_host`); move them to shared util functions or extensions under `lib/src/core/utils`.
- Do not use `SizedBox` only for visual gaps between children in `Row`/`Column`; prefer the built-in `spacing` property on `Row`/`Column`.
- Prefer `Theme.of(context).textTheme` styles and `copyWith` for text styling; avoid creating ad-hoc full `TextStyle(...)` objects unless there is no suitable theme base style.

## Infra

CI is defined in `.github/workflows/flutter.yml` and should run:

```sh
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

The minimum expected local verification before handing off changes is:

```sh
fvm dart format lib test
fvm flutter analyze
fvm flutter test
```

Network requests are cached in memory with `cached_query`. Keep cache keys stable, serializable, and semantic in the TanStack Query style. Prefer keys from `HnQueryKeys`, such as `['hn', 'item', id]` and `['hn', 'storyIds', type.name]`; endpoint paths are fetcher details, not cache-key design.

## Platform Notes

- Android requires `android.permission.INTERNET` in the main manifest because the app calls the Hacker News API.
- macOS requires `com.apple.security.network.client` in entitlements for sandboxed network access.
- iOS uses the default network policy for HTTPS requests to the Hacker News API.
- Web is intentionally removed.

## Git Hygiene

Commit source, configuration, platform templates, lockfiles, and tests.

Commit messages:

- Use Conventional Commits: `<type>(optional-scope): <description>`.
- Use common types such as `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `build`, and `chore`.
- Keep the description concise, imperative, and lowercase unless it contains a proper noun.
- Add a readable scope when it helps, for example `style(items): compact story rank column`.
- Avoid vague generated-agent wording such as `codex changes`, `update files`, or `misc fixes`.
- Mention tests, docs, or platform updates in the body when they are part of the change.

Pull request titles:

- Use the same Conventional Commits shape as commit subjects: `<type>(optional-scope): <description>`.
- Do not prefix PR titles with `codex`.
- Prefer readable titles such as `style(items): compact feed layout` or `docs(agent): document Flutter workflow`.

Do not commit:

- `.dart_tool/`
- `.fvm/`
- `build/`
- IDE workspace state such as `.idea/` and `xcuserdata/`
- generated Flutter environment files such as `Generated.xcconfig` and `flutter_export_environment.sh`
- local Android files such as `local.properties`
