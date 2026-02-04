import 'package:flutter/widgets.dart';
import 'air_controller.dart';
import 'air_builder.dart';
import 'air_state_base.dart';

/// Base class for typed state keys.
///
/// This abstract class allows defining strong types for state keys, avoiding magic strings
/// and enabling type-safe interaction with the [Air] state management system.
///
/// Subclasses should define the generic type [T] representing the type of data held in state.
abstract class AirStateKey<T> {
  /// The unique string identifier used in the [Air] state map.
  final String key;

  /// The default value returned when the state has not been initialized.
  ///
  /// If [defaultValue] is null and the state is accessed without being set,
  /// an error may occur depending on the context.
  final T? defaultValue;

  /// Creates an [AirStateKey] with a required [key] and optional [defaultValue].
  const AirStateKey(this.key, {this.defaultValue});

  @override
  String toString() => 'AirStateKey<$T>($key)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AirStateKey<T> &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}

/// A simple implementation of [AirStateKey] for quick usage.
///
/// Use this when you don't need to create a custom subclass for your keys.
///
/// Example:
/// ```dart
/// static const counterKey = SimpleStateKey<int>('counter', defaultValue: 0);
/// ```
class SimpleStateKey<T> extends AirStateKey<T> {
  const SimpleStateKey(super.key, {super.defaultValue});
}

/// Extension to [Air] singleton for typed state access.
extension TypedAirState on Air {
  /// Retrieves the value of a state using a [AirStateKey].
  ///
  /// If the state does not exist in [Air], it tries to create it using `initialValue`
  /// or returns the key's default value.
  T typedGet<T>(AirStateKey<T> stateKey) {
    try {
      return state<T>(stateKey.key, initialValue: stateKey.defaultValue).value;
    } catch (_) {
      if (stateKey.defaultValue != null) {
        return stateKey.defaultValue as T;
      }
      rethrow;
    }
  }

  /// Flows (sets) a value into the state using a [AirStateKey].
  ///
  /// If the state does not exist, it will be initialized.
  /// - [value]: The new value to set.
  /// - [sourceModuleId]: Optional ID of the module initiating the change (for analytics/debugging).
  void typedFlow<T>(
    AirStateKey<T> stateKey,
    T value, {
    String? sourceModuleId,
  }) {
    state<T>(
      stateKey.key,
      initialValue: stateKey.defaultValue ?? value,
    ).setValue(value, sourceModuleId: sourceModuleId);
  }

  /// Retrieves the [AirController] associated with a [AirStateKey].
  ///
  /// This allows direct access to the controller for adding listeners or other advanced operations.
  AirController<T> typedController<T>(AirStateKey<T> stateKey) {
    return state<T>(stateKey.key, initialValue: stateKey.defaultValue);
  }

  /// Checks if a state associated with a [AirStateKey] currently exists in memory.
  bool typedExists<T>(AirStateKey<T> stateKey) {
    return debugStates.containsKey(stateKey.key);
  }

  /// Removes the state associated with a [AirStateKey] from memory.
  void typedRemove<T>(AirStateKey<T> stateKey) {
    dispose(stateKey.key);
  }
}

/// Extension to [AirState] base class for typed key support.
extension TypedAirStateBase on AirState {
  /// Flows a value using a typed key (convenience method).
  ///
  /// Automatically passes the current `moduleId` as the source of the change.
  void typedFlow<T>(AirStateKey<T> stateKey, T value) {
    flow<T>(stateKey.key, value, sourceModuleId: moduleId);
  }
}

/// Extension for building widgets or accessing values directly from an [AirStateKey].
extension AirStateKeyBuilder<T> on AirStateKey<T> {
  /// Builds a widget that listens to this state key.
  ///
  /// The [builder] is called whenever the state value associated with this key changes.
  Widget build(Widget Function(BuildContext context, T value) builder) {
    return AirBuilder<T>(
      stateKey: key,
      initialValue: defaultValue,
      builder: builder,
    );
  }

  /// Gets the current value from global state.
  T get value => Air().state<T>(key, initialValue: defaultValue).value;

  /// Sets the current value in global state.
  set value(T newValue) =>
      Air().state<T>(key, initialValue: defaultValue).value = newValue;
}

/// Extension for building widgets from a pair of [AirStateKey]s.
extension AirStateKeyBuilder2<T1, T2> on (AirStateKey<T1>, AirStateKey<T2>) {
  /// Builds a widget that listens to both state keys in the tuple.
  ///
  /// The [builder] is called whenever either state changes.
  Widget build(Widget Function(BuildContext context, T1 v1, T2 v2) builder) {
    return AirBuilder2<T1, T2>(
      key1: $1.key,
      initial1: $1.defaultValue,
      key2: $2.key,
      initial2: $2.defaultValue,
      builder: builder,
    );
  }
}

/// Extension for building widgets from a triplet of [AirStateKey]s.
extension AirStateKeyBuilder3<T1, T2, T3>
    on (AirStateKey<T1>, AirStateKey<T2>, AirStateKey<T3>) {
  /// Builds a widget that listens to all three state keys in the tuple.
  ///
  /// The [builder] is called whenever any of the three states changes.
  Widget build(
    Widget Function(BuildContext context, T1 v1, T2 v2, T3 v3) builder,
  ) {
    return AirBuilder3<T1, T2, T3>(
      key1: $1.key,
      initial1: $1.defaultValue,
      key2: $2.key,
      initial2: $2.defaultValue,
      key3: $3.key,
      initial3: $3.defaultValue,
      builder: builder,
    );
  }
}
