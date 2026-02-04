import 'package:flutter/foundation.dart';
import 'delegate.dart';
import 'air_pulse.dart';

/// Registration wrapper for observers with unique ID for proper cleanup
/// Registration wrapper for observers with unique ID for proper cleanup.
///
/// Keeps track of a [callback] and its associated [id] to allow safe removal
/// from observer lists.
class _ObserverRegistration<T> {
  /// The unique identifier for this registration.
  final String id;

  /// The observer callback function.
  final T callback;

  _ObserverRegistration(this.id, this.callback);
}

/// A reactive state container for 'Air'
/// A reactive state container for the Air Framework.
///
/// [AirController] holds a value of type [T] and notifies listeners when the value changes.
/// It integrates with the [Air] system to allow global access and automatic dependency tracking
/// with [AirBuilder] and [AirView].
class AirController<T> extends ChangeNotifier {
  T _value;

  /// The unique key identifying this state in the [Air] system.
  final String key;

  /// Creates a new [AirController] with an initial [_value] and a required [key].
  AirController(this._value, {required this.key});

  /// The current value of the state.
  ///
  /// Accessing this property inside an [AirBuilder] or [AirView] will automatically
  /// register the widget as a listener to this controller, causing it to rebuild
  /// when the value changes.
  T get value {
    // Auto-subscribe if we are inside an AirView
    if (Air.activeWatcher != null) {
      Air.activeWatcher!.register(this);
    }
    return _value;
  }

  /// Updates the value and notifies listeners if the value has changed.
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    Air().notifyStateChange(key, newValue);
    notifyListeners();
  }

  /// Updates value with source tracking for AirGraph.
  ///
  /// Use [force] to notify even when value equals current (for mutable objects).
  ///
  /// The [sourceModuleId] parameter is used to track which module initiated the change.
  /// [silent] prevents notification of listeners (useful for time-travel or initial setup).
  void setValue(
    T newValue, {
    String? sourceModuleId,
    bool silent = false,
    bool force = false,
  }) {
    // Skip notification if value unchanged, unless force is true
    if (!force && _value == newValue) return;
    _value = newValue;

    // If we have a source, treat it as a data interaction
    // We assume the state key itself might contain module prefix like 'auth.user'
    if (sourceModuleId != null) {
      final targetModuleId = key.contains('.') ? key.split('.').first : null;
      if (targetModuleId != null && targetModuleId != sourceModuleId) {
        Air.delegate.recordInteraction(
          sourceModuleId,
          targetModuleId,
          'data', // InteractionType.data
          key,
        );
      }
    }

    // Only notify when not silent (used by AirSnap time-travel)
    if (!silent) {
      Air().notifyStateChange(key, newValue);
      notifyListeners();
    }
  }

  /// Forces notification to listeners after in-place mutation.
  ///
  /// Use this when you mutate the value directly (e.g., list.add()) and need to
  /// trigger a rebuild.
  void forceNotify({String? sourceModuleId}) {
    if (sourceModuleId != null) {
      final targetModuleId = key.contains('.') ? key.split('.').first : null;
      if (targetModuleId != null && targetModuleId != sourceModuleId) {
        Air.delegate.recordInteraction(
          sourceModuleId,
          targetModuleId,
          'data',
          key,
        );
      }
    }
    Air().notifyStateChange(key, _value);
    notifyListeners();
  }

  /// Updates the value using a transformation function [updater].
  ///
  /// The [updater] receives the current value and should return the new value.
  void update(T Function(T current) updater) {
    // Since we modifying value via updater, we need to manually trigger setter
    // or notifyListeners. Accessing .value here might trigger subscription
    // if inside watcher, which is desired.
    value = updater(_value);
  }
}

/// The main 'Air' state manager singleton.
///
/// Handles global state registration, retrieval, and observation.
class Air {
  static final Air _instance = Air._internal();

  /// Returns the singleton instance of [Air].
  factory Air() => _instance;
  Air._internal();

  /// The delegate that handles external communication (Logging, Security, EventBus).
  static AirDelegate delegate = DefaultAirDelegate();

  /// Configure the delegate for custom handling of interactions and events.
  static void configure({required AirDelegate delegate}) {
    Air.delegate = delegate;
  }

  final Map<String, AirController<dynamic>> _states = {};

  // ID-based observers for proper cleanup when widgets are disposed
  int _observerIdCounter = 0;
  final List<_ObserverRegistration<void Function(String, dynamic)>>
  _actionObservers = [];
  final List<_ObserverRegistration<void Function(String, dynamic)>>
  _stateObservers = [];

  // Currently building watcher (for automatic dependency injection)
  static AirWatcher? activeWatcher;

  /// Adds an action observer and returns its ID for later removal.
  ///
  /// [observer] will be called whenever an action is pulsed through the system.
  String addActionObserver(
    void Function(String action, dynamic data) observer,
  ) {
    final id = 'action_obs_${++_observerIdCounter}';
    _actionObservers.add(_ObserverRegistration(id, observer));
    return id;
  }

  /// Remove an action observer by callback reference (legacy support).
  ///
  /// It is recommended to use [removeActionObserverById] instead.
  void removeActionObserver(
    void Function(String action, dynamic data) observer,
  ) {
    _actionObservers.removeWhere((reg) => reg.callback == observer);
  }

  /// Removes an action observer by its unique ID.
  void removeActionObserverById(String id) {
    _actionObservers.removeWhere((reg) => reg.id == id);
  }

  /// Adds a state observer and returns its ID for later removal.
  ///
  /// [observer] will be called whenever any state managed by [Air] changes.
  String addStateObserver(void Function(String key, dynamic value) observer) {
    final id = 'state_obs_${++_observerIdCounter}';
    _stateObservers.add(_ObserverRegistration(id, observer));
    return id;
  }

  /// Remove a state observer by callback reference (legacy support)
  void removeStateObserver(void Function(String key, dynamic value) observer) {
    _stateObservers.removeWhere((reg) => reg.callback == observer);
  }

  /// Removes a state observer by its unique ID.
  void removeStateObserverById(String id) {
    _stateObservers.removeWhere((reg) => reg.id == id);
  }

  void _notifyAction(String action, dynamic data) {
    // Create copy to safely iterate while callbacks may modify the list
    final observers = List.of(_actionObservers);
    for (var reg in observers) {
      reg.callback(action, data);
    }
  }

  void notifyStateChange(String key, dynamic value) {
    // Create copy to safely iterate while callbacks may modify the list
    final observers = List.of(_stateObservers);
    for (var reg in observers) {
      reg.callback(key, value);
    }
  }

  /// Expose states for DevTools or debugging purposes.
  Map<String, AirController<dynamic>> get debugStates =>
      Map.unmodifiable(_states);

  /// Access a state by [key]. Creates it if it doesn't exist.
  ///
  /// If the state needs to be created, [initialValue] must be provided.
  /// Throws [StateError] if the key exists but with a different type [T].
  /// Throws [ArgumentError] if the key does not exist and [initialValue] is missing.
  AirController<T> state<T>(String key, {T? initialValue}) {
    final existing = _states[key];
    if (existing != null) {
      if (existing is! AirController<T>) {
        throw StateError(
          'State key "$key" already exists with type ${existing.value.runtimeType}, '
          'but requested type $T',
        );
      }
      return existing;
    }

    if (initialValue == null && null is! T) {
      throw ArgumentError(
        'Initial value required for new state "$key" of type $T',
      );
    }
    final controller = AirController<T>(initialValue as T, key: key);
    _states[key] = controller;
    return controller;
  }

  /// Clear all states (mainly for testing).
  void clear() {
    for (var controller in _states.values) {
      controller.dispose();
    }
    _states.clear();
  }

  /// Reset the entire Air instance (for testing).
  ///
  /// Clears all states and removes all observers.
  @visibleForTesting
  void reset() {
    // Dispose all controllers
    for (var controller in _states.values) {
      controller.dispose();
    }
    _states.clear();

    // Clear all observers
    _actionObservers.clear();
    _stateObservers.clear();
  }

  /// Remove a state by [key].
  void dispose(String key) {
    _states.remove(key)?.dispose();
  }

  /// Emit a signal through the EventBus with named parameters and callbacks.
  ///
  /// - [action]: The name of the action to pulse.
  /// - [params]: The payload data associated with the action.
  /// - [sourceModuleId]: The ID of the module initiating the pulse.
  /// - [onSuccess]: Optional callback executed on successful handling.
  /// - [onError]: Optional callback executed on error.
  void pulse({
    required String action,
    dynamic params,
    String? sourceModuleId,
    VoidCallback? onSuccess,
    void Function(String)? onError,
  }) {
    _notifyAction(action, params);

    // Delegate the actual emission to the framework adapter
    // Wrap params in AirAction if it's not already?
    // In original code, it emitted AirAction.
    // The delegate interface takes `dynamic params`.
    // We should pass the raw params and let the delegate wrap it or handle it.
    // But wait, the original code wrapped it in AirAction ONLY for the EventBus.
    // The AirAction class wrapper was inside pulse.
    // "EventBus().emitSignal(..., data: AirAction(...))"

    // So here we should pass the AirAction object as 'params' to the delegate?
    // Or should the delegate API be clean?
    // The delegate API `pulse(String action, dynamic params)` implies sending data.
    // If the receiving side expects AirAction, we should send AirAction.

    final payload = AirAction(params, onSuccess: onSuccess, onError: onError);
    delegate.pulse(action, payload, sourceId: sourceModuleId);
  }
}

/// Interface for any widget/entity that wants to automatically track dependencies
abstract class AirWatcher {
  void register(AirController controller);
}
