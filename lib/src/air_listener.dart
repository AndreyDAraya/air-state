import 'package:flutter/widgets.dart';
import 'air_controller.dart';
import 'typed_state_key.dart';

/// A widget that listens to a list of [AirStateKey]s and executes a
/// side effect [listener] when any of them changes, without rebuilding the UI.
///
/// Use this widget to trigger actions like navigation, SnackBars, or dialogs
/// in response to state changes.
///
/// Example:
/// ```dart
/// AirListener(
///   listen: [AuthFlows.isAuthenticated, AuthFlows.error],
///   listener: (context) {
///     if (AuthFlows.isAuthenticated.value) {
///       context.go('/');
///     }
///     if (AuthFlows.error.value != null) {
///       ScaffoldMessenger.of(context).showSnackBar(...);
///     }
///   },
///   child: MyForm(),
/// )
/// ```
class AirListener extends StatefulWidget {
  /// The list of state keys to observe for changes.
  final List<AirStateKey> listen;

  /// The callback that will be triggered when any observed state changes.
  final void Function(BuildContext context) listener;

  /// The child widget.
  final Widget child;

  const AirListener({
    super.key,
    required this.listen,
    required this.listener,
    required this.child,
  });

  @override
  State<AirListener> createState() => _AirListenerState();
}

class _AirListenerState extends State<AirListener> {
  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(AirListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.listen, widget.listen)) {
      _unsubscribe(oldWidget.listen);
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe(widget.listen);
    super.dispose();
  }

  void _subscribe() {
    for (final key in widget.listen) {
      Air().typedController(key).addListener(_onStateChanged);
    }
  }

  void _unsubscribe(List<AirStateKey> keys) {
    for (final key in keys) {
      Air().typedController(key).removeListener(_onStateChanged);
    }
  }

  void _onStateChanged() {
    // Ensuring the listener is called safely. If the widget is not mounted, do nothing.
    if (!mounted) return;
    widget.listener(context);
  }

  // Simple list equality check to avoid importing collection specifically
  bool _listEquals(List<AirStateKey> a, List<AirStateKey> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
