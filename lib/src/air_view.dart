import 'package:flutter/material.dart';
import 'air_controller.dart';

/// A reactive widget that automatically rebuilds when accessed states change.
///
/// Any [AirController] value accessed within the [builder] will be tracked
/// as a dependency. When those dependencies change, this widget rebuilds.
///
/// Example:
/// ```dart
/// AirView((context) {
///   if (CounterState.count.value > 5) return Text('High!');
///   return Text('${CounterState.count.value}');
/// })
/// ```
class AirView extends StatefulWidget {
  /// The builder function that builds the UI and tracks state accesses.
  final WidgetBuilder builder;

  const AirView(this.builder, {super.key});

  @override
  State<AirView> createState() => _AirViewState();
}

class _AirViewState extends State<AirView> implements AirWatcher {
  // Use a set to avoid duplicate registrations
  final Set<AirController> _dependencies = {};

  // Track dependencies for the *current* build to handle conditional logic
  Set<AirController> _newDependencies = {};

  @override
  void register(AirController controller) {
    _newDependencies.add(controller);
  }

  void _onDependencyChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 1. Prepare to track
    _newDependencies = {};
    final previousWatcher = Air.activeWatcher;
    Air.activeWatcher = this;

    Widget result;
    try {
      // 2. Build and track
      result = widget.builder(context);
    } finally {
      // 3. Restore previous watcher (if nested)
      Air.activeWatcher = previousWatcher;

      // 4. Update subscriptions
      // Unsubscribe from removed deps
      for (final dep in _dependencies) {
        if (!_newDependencies.contains(dep)) {
          dep.removeListener(_onDependencyChanged);
        }
      }

      // Subscribe to new deps
      for (final dep in _newDependencies) {
        if (!_dependencies.contains(dep)) {
          dep.addListener(_onDependencyChanged);
        }
      }

      // Swap sets
      _dependencies.clear();
      _dependencies.addAll(_newDependencies);
    }
    return result;
  }

  @override
  void dispose() {
    for (final dep in _dependencies) {
      dep.removeListener(_onDependencyChanged);
    }
    super.dispose();
  }
}
