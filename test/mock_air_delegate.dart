import 'package:air_state/air_state.dart';

class MockAirDelegate implements AirDelegate {
  final List<String> logs = [];
  final List<Map<String, dynamic>> pulses = [];
  final List<Map<String, String>> interactions = [];

  @override
  void log(
    String message, {
    Map<String, dynamic>? context,
    bool isError = false,
  }) {
    logs.add(message);
  }

  @override
  void pulse(String action, dynamic params, {String? sourceId}) {
    pulses.add({'action': action, 'params': params, 'sourceId': sourceId});
  }

  @override
  void recordInteraction(
    String sourceId,
    String targetId,
    String type,
    String detail,
  ) {
    interactions.add({
      'sourceId': sourceId,
      'targetId': targetId,
      'type': type,
      'detail': detail,
    });
  }

  @override
  dynamic subscribe(String action, void Function(dynamic) callback) {
    // No-op for mock unless needed
  }
}
