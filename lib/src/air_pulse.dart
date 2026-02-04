import 'package:flutter/foundation.dart';
import 'air_controller.dart';

/// A wrapper for Air actions to carry data and callbacks
class AirAction {
  final dynamic data;
  final VoidCallback? onSuccess;
  final void Function(String)? onError;

  AirAction(this.data, {this.onSuccess, this.onError});
}

/// A strictly named and typed signal
class AirPulse<T> {
  final String name;
  const AirPulse(this.name);

  /// Emit this signal with type-safe parameters
  void pulse(
    T params, {
    String? sourceModuleId,
    VoidCallback? onSuccess,
    void Function(String)? onError,
  }) {
    // Infer source from name if not provided (e.g. "tasks.add" -> "tasks")
    final source =
        sourceModuleId ?? (name.contains('.') ? name.split('.').first : null);

    Air().pulse(
      action: name,
      params: params,
      sourceModuleId: source,
      onSuccess: onSuccess,
      onError: onError,
    );
  }
}
