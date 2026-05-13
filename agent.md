# Agent Guide

## Project

Hacker Pen is a Flutter app for reading Hacker News. The project intentionally does not support Flutter Web; do not recreate or commit a `web/` directory.

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

Do not commit:

- `.dart_tool/`
- `.fvm/`
- `build/`
- IDE workspace state such as `.idea/` and `xcuserdata/`
- generated Flutter environment files such as `Generated.xcconfig` and `flutter_export_environment.sh`
- local Android files such as `local.properties`
