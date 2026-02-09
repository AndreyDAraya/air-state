import 'package:flutter/material.dart';
import 'air_controller.dart';

/// A reactive widget that builds based on an [AirController].
///
/// Automatically creates or retrieves the state identified by [stateKey]
/// and rebuilds when that state changes.
class AirBuilder<T> extends StatefulWidget {
  /// The key identifying the state to listen to.
  final String stateKey;

  /// The initial value if the state needs to be created.
  final T? initialValue;

  /// Optional module ID of the caller for dependency tracking.
  final String? callerModuleId;

  /// The builder function invoked when state changes.
  final Widget Function(BuildContext context, T value) builder;

  const AirBuilder({
    super.key,
    required this.stateKey,
    this.initialValue,
    this.callerModuleId,
    required this.builder,
  });

  @override
  State<AirBuilder<T>> createState() => _AirBuilderState<T>();
}

class _AirBuilderState<T> extends State<AirBuilder<T>> {
  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    // Check if the caller has permission to access this state
    final hasAccess = Air.delegate.canAccess(
      widget.stateKey,
      sourceId: widget.callerModuleId,
    );

    if (!hasAccess) {
      throw Exception(
        'Access Denied: Module "${widget.callerModuleId}" does not have permission '
        'to access state "${widget.stateKey}".',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // We pass callerModuleId to the state method to ensure subscription tracking
    final airController = Air().state<T>(
      widget.stateKey,
      initialValue: widget.initialValue,
    );

    return ListenableBuilder(
      listenable: airController,
      builder: (context, _) {
        return widget.builder(context, airController.value);
      },
    );
  }
}

/// A reactive widget that builds based on two AirControllers
class AirBuilder2<T1, T2> extends StatelessWidget {
  final String key1;
  final T1? initial1;
  final String key2;
  final T2? initial2;
  final String? callerModuleId;
  final Widget Function(BuildContext context, T1 v1, T2 v2) builder;

  const AirBuilder2({
    super.key,
    required this.key1,
    this.initial1,
    required this.key2,
    this.initial2,
    this.callerModuleId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AirBuilder<T1>(
      stateKey: key1,
      initialValue: initial1,
      callerModuleId: callerModuleId,
      builder: (context, v1) {
        return AirBuilder<T2>(
          stateKey: key2,
          initialValue: initial2,
          callerModuleId: callerModuleId,
          builder: (context, v2) {
            return builder(context, v1, v2);
          },
        );
      },
    );
  }
}

/// A reactive widget that builds based on three AirControllers
class AirBuilder3<T1, T2, T3> extends StatelessWidget {
  final String key1;
  final T1? initial1;
  final String key2;
  final T2? initial2;
  final String key3;
  final T3? initial3;
  final String? callerModuleId;
  final Widget Function(BuildContext context, T1 v1, T2 v2, T3 v3) builder;

  const AirBuilder3({
    super.key,
    required this.key1,
    this.initial1,
    required this.key2,
    this.initial2,
    required this.key3,
    this.initial3,
    this.callerModuleId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AirBuilder2<T1, T2>(
      key1: key1,
      initial1: initial1,
      key2: key2,
      initial2: initial2,
      callerModuleId: callerModuleId,
      builder: (context, v1, v2) {
        return AirBuilder<T3>(
          stateKey: key3,
          initialValue: initial3,
          callerModuleId: callerModuleId,
          builder: (context, v3) {
            return builder(context, v1, v2, v3);
          },
        );
      },
    );
  }
}
