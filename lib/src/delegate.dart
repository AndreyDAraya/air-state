import 'dart:async';

/// Delegate interface for Air State to interact with the outer framework
/// This allows decoupling from specific EventBus or Logger implementations.
abstract class AirDelegate {
  /// Log a message (debug, info, warning)
  void log(
    String message, {
    Map<String, dynamic>? context,
    bool isError = false,
  });

  /// RECORD a module interaction for analytics/security
  void recordInteraction(
    String sourceId,
    String targetId,
    String type,
    String detail,
  );

  /// Check if a source has permission to access a state key
  bool canAccess(String key, {String? sourceId});

  /// Emit a pulse/action to the system
  void pulse(String action, dynamic params, {String? sourceId});

  /// Subscribe to a system pulse/action
  /// Returns a subscription object that implies a `cancel()` method or similar.
  dynamic subscribe(
    String action,
    void Function(dynamic) callback, {
    String? sourceId,
  });
}

/// A default no-op / simple delegate for standalone usage or testing
class DefaultAirDelegate implements AirDelegate {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  @override
  void log(
    String message, {
    Map<String, dynamic>? context,
    bool isError = false,
  }) {
    // In standalone, just print if it's an error or we want basic logs
    if (isError) {
      print('[AirState Error] $message $context');
    }
  }

  @override
  void recordInteraction(
    String sourceId,
    String targetId,
    String type,
    String detail,
  ) {
    // No-op in default helper
  }

  @override
  bool canAccess(String key, {String? sourceId}) {
    // Default allows all access
    return true;
  }

  @override
  void pulse(String action, dynamic params, {String? sourceId}) {
    _controller.add({'action': action, 'data': params, 'source': sourceId});
  }

  @override
  dynamic subscribe(
    String action,
    void Function(dynamic) callback, {
    String? sourceId,
  }) {
    return _controller.stream.listen((event) {
      if (event['action'] == action) {
        callback(event['data']);
      }
    });
  }
}
