import 'package:flutter/foundation.dart';
import 'air_controller.dart';

/// A computed state that derives from other states
class ComputedState<T> {
  /// List of state keys this computation depends on
  final List<String> dependencies;

  /// Function to compute the derived value
  final T Function(Map<String, dynamic> states) compute;

  /// Optional debug name
  final String? name;

  const ComputedState({
    required this.dependencies,
    required this.compute,
    this.name,
  });

  /// Evaluate this computed state with current Air state values
  T evaluate() {
    final states = <String, dynamic>{};
    for (final key in dependencies) {
      final controller = Air().debugStates[key];
      states[key] = controller?.value;
    }
    return compute(states);
  }
}

/// Manager for reactive computed states
class ComputedStateManager {
  static final ComputedStateManager _instance = ComputedStateManager._();
  factory ComputedStateManager() => _instance;
  ComputedStateManager._();

  final Map<String, _ComputedRegistration> _registrations = {};
  final Map<String, String> _observerIds = {};

  /// Register a computed state that automatically updates
  void register<T>(String targetKey, ComputedState<T> computed) {
    // Clean up existing registration
    unregister(targetKey);

    // Watch changes using state observer
    final observerId = Air().addStateObserver((key, value) {
      if (computed.dependencies.contains(key)) {
        _updateComputed(targetKey, computed);
      }
    });

    _observerIds[targetKey] = observerId;
    _registrations[targetKey] = _ComputedRegistration(
      computed: computed,
      lastValue: null,
    );

    // Initial computation
    _updateComputed(targetKey, computed);

    Air.delegate.log(
      'Registered computed state',
      context: {'key': targetKey, 'dependencies': computed.dependencies},
    );
  }

  void _updateComputed<T>(String targetKey, ComputedState<T> computed) {
    try {
      final newValue = computed.evaluate();
      final registration = _registrations[targetKey];

      // Only update if value changed
      if (registration?.lastValue != newValue) {
        Air()
            .state<T>(targetKey, initialValue: newValue)
            .setValue(newValue, sourceModuleId: 'computed');
        _registrations[targetKey] = _ComputedRegistration(
          computed: computed,
          lastValue: newValue,
        );
      }
    } catch (e) {
      Air.delegate.log(
        'Error computing state',
        context: {'key': targetKey},
        isError: true,
      );
    }
  }

  /// Unregister a computed state
  void unregister(String targetKey) {
    final observerId = _observerIds.remove(targetKey);
    if (observerId != null) {
      Air().removeStateObserverById(observerId);
    }
    _registrations.remove(targetKey);
  }

  /// Check if a key is a registered computed state
  bool isComputed(String key) => _registrations.containsKey(key);

  /// Get all registered computed state keys
  List<String> get registeredKeys => _registrations.keys.toList();

  /// Clear all registrations (for testing)
  @visibleForTesting
  void clear() {
    if (!kDebugMode) return;
    for (final key in _registrations.keys.toList()) {
      unregister(key);
    }
  }
}

class _ComputedRegistration {
  final ComputedState computed;
  final dynamic lastValue;
  _ComputedRegistration({required this.computed, this.lastValue});
}

/// Extension to Air for computed state support
extension ComputedAirState on Air {
  /// Evaluate a computed state with current values
  T computed<T>(ComputedState<T> spec) {
    return spec.evaluate();
  }

  /// Register a reactive computed state
  void registerComputed<T>(String targetKey, ComputedState<T> computed) {
    ComputedStateManager().register<T>(targetKey, computed);
  }

  /// Unregister a reactive computed state
  void unregisterComputed(String targetKey) {
    ComputedStateManager().unregister(targetKey);
  }

  /// Check if a key is a computed state
  bool isComputed(String key) {
    return ComputedStateManager().isComputed(key);
  }
}

/// Shorthand for creating computed states
ComputedState<T> createComputed<T>({
  required List<String> deps,
  required T Function(Map<String, dynamic> states) compute,
  String? name,
}) {
  return ComputedState<T>(dependencies: deps, compute: compute, name: name);
}
