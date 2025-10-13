# Repository Guidelines

## Project Structure & Module Organization
- `lib/main.dart` bootstraps the Flutter app and wires Firebase options.
- Feature views live under `lib/screens`, with shared UI in `lib/widgets` and data access in `lib/services`.
- Generated Firebase config is tracked in `lib/firebase_options.dart`; keep environment-specific variants in secure storage when regenerating.
- Platform runners sit under `android/`, `ios/`, `macos/`, `linux/`, `web/`, and `windows/`. Only touch them when platform-specific configuration changes.
- Tests live in `test/`, mirroring the `lib/` structure (e.g., `test/screens/...`).

## Build, Test & Development Commands
- `flutter pub get` installs Dart and Flutter dependencies defined in `pubspec.yaml`.
- `flutter run -d <device>` launches the app on a connected emulator or device.
- `flutter build apk` (or `flutter build ios`) produces release artifacts; use after version bumps.
- `flutter analyze` enforces lint rules before sending a pull request.
- `flutter test` executes the unit and widget test suite; pair with `--coverage` when updating metrics.

## Coding Style & Naming Conventions
- Follow the lints from `analysis_options.yaml` (Flutter recommended set). Keep imports ordered and eliminate dead code.
- Prefer `dart format .` to maintain two-space indentation and trailing commas for multi-line constructors.
- Name widgets and controllers with `PascalCase`, methods and variables with `camelCase`, and constants with `kPrefix`.
- Co-locate screen-specific helpers under the matching screen directory to avoid cross-feature coupling.

## Testing Guidelines
- Place new tests alongside the feature under `test/`, using filenames like `screen_name_test.dart`.
- Use `WidgetTester` for UI flows and mock services to isolate Firebase interactions.
- Aim to expand coverage around new services; document gaps in the pull request if a test is impractical.
- Run `flutter test --coverage` locally and verify `coverage/lcov.info` updates before submitting.

## Commit & PR Guidelines
- Follow the short, imperative commit style seen in history (e.g., `health profile`); keep commits scoped to one concern.
- Reference issue IDs in the subject when applicable (`health profile #123`) and include context in the body if behaviour changes.
- Pull requests should summarize the change, list testing evidence, attach relevant screenshots, and highlight any configuration steps (Firebase, platform files).
- Request review from a teammate familiar with the touched module and wait for CI green before merging.

## Environment & Configuration
- Keep secrets out of the repo; rely on `.env`-style runtime configuration and exclude any regenerated `google-services` files.
- Update `firebase.json` and `lib/firebase_options.dart` via `flutterfire configure`; document the target Firebase project in the PR.
