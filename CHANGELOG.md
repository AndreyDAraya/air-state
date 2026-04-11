# Changelog

## 1.0.5

### Improvements

- **AirListener**: Introduced the `AirListener` widget for handling one-off side effects (navigation, SnackBars) reactively without triggering UI rebuilds. This component promotes better separation of concerns and keeps the widget `build` methods pure.

## 1.0.4

### Bug Fixes

- **Fixed silent data loss in `StatePersistence._serialize()`**: Custom model objects with `toJson()` or `toMap()` methods now serialize correctly. Previously, the existence check `obj.toJson != null` always threw `NoSuchMethodError` (swallowed by a catch), causing all custom models to fall back to `.toString()` — making restore impossible. Now calls `toJson()`/`toMap()` directly inside a try-catch.
- **Fixed subscription leaks in `AirState.dispose()`**: Simplified the disposal logic to a single `try { (sub as dynamic).cancel() } catch (_) {}` block. The previous implementation had unreachable branches and silently swallowed cancellation errors, leaving subscriptions alive after dispose.
- **Removed unused `dart:async` import** from `air_state_base.dart`.

## 1.0.3

- **Visual Identity**: Added the official Air Framework SVG logo.
- **Documentation**: Updated README with the new logo and visual assets.

## 1.0.2

- **Security & Access Control**:
  - Added `canAccess` method to `AirDelegate` to validate state access permissions.
  - Updated `AirBuilder` to check for access permissions before building.
  - Added `sourceId` tracking to `AirDelegate.subscribe` and `AirState` event listeners.
- **API Improvements**:
  - `AirBuilder`, `AirBuilder2`, and `AirBuilder3` now accept `callerModuleId` for better dependency tracking.
  - Updated `AirDelegate` interface signature

## 1.0.1

- Updated examples and internal documentation links.

## 1.0.0

- Initial release of `air_state`.
- Core reactive state management (`AirController`, `Air`).
- Typed state keys support (`AirStateKey`).
- Widget builders (`AirBuilder`, `AirView`).
- Helper extensions for Tuples.
