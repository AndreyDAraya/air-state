# Air State Example

This example demonstrates the core features of `air_state`:

- **Typed Keys**: Defining strict keys for state access.
- **AirBuilder**: Reactive widget rebuilding.
- **AirView**: Automatic dependency tracking.
- **Direct Updates**: Modifying state via `.value` setters.

## Getting Started

1. From the root of the repository, run:

   ```bash
   flutter pub get
   ```

2. Run the example:
   ```bash
   flutter run packages/air_state/example/lib/main.dart
   ```

## Code Highlights

### Defining Keys

```dart
const counterKey = SimpleStateKey<int>('counter', defaultValue: 0);
```

### Reading & Listening

```dart
// Using AirView (Automatic)
AirView((context) {
  return Text('Hello, ${counterKey.value}');
});

// Using Builder (Explicit)
counterKey.build((context, value) {
  return Text('$value');
});
```

### Updating State

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () {
    counterKey.value++; // Triggers rebuilds automatically
  },
  // ...
),
```
