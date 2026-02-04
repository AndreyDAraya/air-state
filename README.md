# Air State

A lightweight, modular, and reactive state management library designed for the Air Framework, but usable in any Flutter application.

`air_state` provides a clean API for managing global state, tracking dependencies, and building reactive UIs without boilerplate.

## Features

- **Global State Access**: Access state from anywhere using keys.
- **Typed Keys**: Use `AirStateKey<T>` for type cleanliness and safety.
- **Reactivity**: Widgets like `AirBuilder` and `AirView` automatically rebuild when state changes.
- **Modularity**: Designed to work with independent modules.
- **Pulsing**: Event-driven communication via `Air.pulse`.

## Installation

Add `air_state` to your `pubspec.yaml`:

```yaml
dependencies:
  air_state: ^1.0.0
```

## Usage

### Basic Usage

1. **Set Value**:

   ```dart
   Air().state<int>('counter', initialValue: 0).value = 5;
   ```

2. **Build UI**:
   ```dart
   AirBuilder<int>(
     stateKey: 'counter',
     initialValue: 0,
     builder: (context, value) => Text('Count: $value'),
   );
   ```

### Typed Keys (Recommended)

Define keys to avoid magic strings:

```dart
// Define a key
const counterKey = SimpleStateKey<int>('counter', defaultValue: 0);

// Set value
Air().typedFlow(counterKey, 10);

// Get value
final count = Air().typedGet(counterKey);

// Build UI
counterKey.build((context, value) {
  return Text('Count: $value');
});
```

### AirView

`AirView` automatically tracks any `AirController` value accessed during its build phase.

```dart
AirView((context) {
  // Automatically rebuilds if 'counter' changes
  return Text('Hello, ${counterKey.value}');
});
```

## Additional Features

- **Observers**: Add global observers for logging or debugging.
- **Event Bus**: Use `Air.pulse` to send signals across the app.
- **Computed State**: Create derived states that update automatically (coming soon).

## License

MIT
