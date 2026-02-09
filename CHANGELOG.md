# Changelog

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
