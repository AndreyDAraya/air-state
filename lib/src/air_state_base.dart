import 'dart:async';
import 'package:flutter/foundation.dart';
import 'air_controller.dart';
import 'air_pulse.dart';

/// Base class for controllers that handle business logic reactively
abstract class AirState {
  final String? moduleId;
  final List<dynamic> _subscriptions = []; // Store subscriptions

  AirState({this.moduleId}) {
    onInit();
    onPulses();
  }

  /// Initialize state and data before listening to signals
  void onInit() {}

  /// Define signal handlers using [on]
  void onPulses();

  /// Internal listener using raw signal name
  void onRaw<T>(
    String action,
    void Function(
      T data, {
      VoidCallback? onSuccess,
      void Function(String error)? onError,
    })
    callback,
  ) {
    // Use the delegate to subscribe
    final sub = Air.delegate.subscribe(action, (eventData) {
      // Adapt the callback
      if (eventData is AirAction) {
        final data = eventData.data;
        if (data is T || (data == null && null is T)) {
          callback(
            data as T,
            onSuccess: eventData.onSuccess,
            onError: eventData.onError,
          );
        } else {
          Air.delegate.log(
            'Air: Signal "$action" received data of type ${data.runtimeType}, but expected $T. Ignoring.',
            isError: true,
          );
        }
      } else if (eventData is T || (eventData == null && null is T)) {
        // Fallback for direct data emission (if supported by delegate)
        callback(eventData as T);
      }
    });

    _subscriptions.add(sub);
  }

  /// Register a handler for a strictly typed AirSignal
  void on<T>(
    AirPulse<T> signal,
    void Function(
      T data, {
      VoidCallback? onSuccess,
      void Function(String error)? onError,
    })
    handler,
  ) {
    onRaw<T>(signal.name, handler);
  }

  /// Emit a signal with this module's context
  void pulse<T>(
    AirPulse<T> signal,
    T params, {
    VoidCallback? onSuccess,
    void Function(String)? onError,
  }) {
    signal.pulse(
      params,
      sourceModuleId: moduleId,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Emit a raw signal with this module's context
  void pulseRaw({
    required String action,
    dynamic params,
    VoidCallback? onSuccess,
    void Function(String)? onError,
  }) {
    Air().pulse(
      action: action,
      params: params,
      sourceModuleId: moduleId,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Conveniently listen to a signal (dynamic)
  void onRawSignal(String signalName, void Function(dynamic data) callback) {
    final sub = Air.delegate.subscribe(signalName, callback);
    _subscriptions.add(sub);
  }

  /// Flow a new value into an Air state with optional tracking
  void flow<T>(String key, T value, {String? sourceModuleId}) {
    Air()
        .state<T>(key, initialValue: value)
        .setValue(value, sourceModuleId: sourceModuleId ?? moduleId);
  }

  /// Dispose all subscriptions
  void dispose() {
    for (var sub in _subscriptions) {
      if (sub is StreamSubscription) {
        sub.cancel();
      } else if (sub is List && sub.isNotEmpty && sub.first is Function) {
        // Handle cancellation if it's a function or object with cancel method
        // Since we don't know exact type from delegate, we try common patterns or user dynamic
        try {
          (sub as dynamic).cancel();
        } catch (_) {}
      } else {
        try {
          (sub as dynamic).cancel();
        } catch (_) {}
      }
    }
    _subscriptions.clear();
  }
}
