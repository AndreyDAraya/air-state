/// The main entry point for the Air State management library.
///
/// Use [Air] to access global state, [AirController] to manage individual state units,
/// and [AirPulse] for event-driven communication.
///
/// Build reactive UIs using [AirBuilder] or [AirView].
library air_state;

export 'src/delegate.dart';
export 'src/air_controller.dart';
export 'src/air_pulse.dart';
export 'src/air_state_base.dart';
export 'src/air_builder.dart';
export 'src/air_view.dart';
export 'src/computed_state.dart';
export 'src/state_persistence.dart';
export 'src/typed_state_key.dart';
