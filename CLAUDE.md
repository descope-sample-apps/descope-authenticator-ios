# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Sample iOS TOTP authenticator app from Descope. Swift 6 with `SWIFT_STRICT_CONCURRENCY = complete`, iOS 15.6+, iPhone only, UIKit with `.xib` views (no SwiftUI). No package dependencies, only Apple frameworks. There is no test target and no lint config.

## Build

```sh
xcodebuild -project Descope.xcodeproj -scheme Descope -destination 'generic/platform=iOS Simulator' build
```

The project does not use synchronized folders: every new source, `.xib`, or resource file must also be added to `Descope.xcodeproj/project.pbxproj` (file reference, group, and build phase), or it silently won't be compiled or bundled.

Info.plist values are split between `res/Info.plist` (URL schemes) and `INFOPLIST_KEY_*` build settings in the pbxproj (camera usage description, launch screen, etc.).

## Architecture

MVVM + coordinators on top of a small Redux-style store. Code is in `src/`, resources in `res/`.

- **Store** (`src/core/model/`): `Model` holds a single `State { client, account }`. Mutate only via `model.dispatch(_:)` with an `Action` (concrete types nested in `enum Actions`). `Reducers.swift` gives each substate a pure `reduce(action:)`; the root reducer fans out to all of them. Delegates are notified after every dispatch. Persisting is **not** automatic: callers must call `model.save()`, which writes `Documents/state.json` on `StorageManager`'s background queue.
- **Secrets stay out of state.** `State` holds only `Key` metadata (issuer, username, algorithm, digits, period). The raw TOTP secret lives in the keychain (`KeychainManager`), keyed by `accountId`, with `kSecAttrSynchronizable = true` (it syncs via iCloud Keychain) and `AfterFirstUnlock` accessibility. `AccountManager` is the only place that should add/remove accounts: it writes the keychain first, then dispatches and saves. Keychain errors are currently swallowed with `try?`.
- **DI and navigation**: `AppDelegate` -> `AppSession` (builds `Model`, `KeychainManagerClass`, `AccountManagerClass`) -> `AppCoordinator` (owns the window and `HomeCoordinator`, presents `AddCoordinator` modally). Each feature folder under `src/views/` has `XCoordinator`, `XViewController` + `.xib`, and `XViewModel`. View models expose a `state` struct and report through a delegate; navigation goes up to the coordinator.
- **Provisioning**: `otpauth://` deep links (`application(_:open:)`) and QR scans both end in `Key.parse(url:)` in `src/others/Keys.swift`. It enforces `totp` only, 6 or 8 digits, and a 30s period. The same file has the RFC 6238 TOTP implementation (CryptoKit HMAC) and a base32 decoder.

## Conventions

- Store, managers, and view layer are `@MainActor`. Only `StorageManager` does work off the main actor.
- Shared services with several observers (`Model`, `AccountManager`) keep delegates in a `WeakCollection<T>` (`src/others/Containers.swift`) exposed through `addDelegate`/`removeDelegate`. Coordinators, view models, and `CameraManager` use a single `weak var delegate`.
- Log with `Log.d/i/w/e` (`src/others/Logging.swift`), never `print`. Output goes to `os_log` as `%{public}@`, so never log secrets or full `otpauth://` URLs.
- Use typed throws (`throws(KeychainManagerError)`, `throws(Key.ParseError)`) where the surrounding API already does.
