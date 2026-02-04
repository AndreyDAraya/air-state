import 'package:flutter_test/flutter_test.dart';
import 'package:air_state/air_state.dart';
import 'mock_air_delegate.dart';

void main() {
  group('AirController Tests', () {
    setUp(() {
      Air().reset();
    });

    test('value getter and setter work correctly', () {
      final controller = AirController<int>(0, key: 'test_counter');
      expect(controller.value, 0);

      controller.value = 1;
      expect(controller.value, 1);
    });

    test('listeners are notified on change', () {
      final controller = AirController<int>(0, key: 'test_counter');
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.value = 1;
      expect(notified, isTrue);
    });

    test('update() modifies value and notifies listeners', () {
      final controller = AirController<int>(10, key: 'test_update');

      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.update((current) => current + 5);
      expect(controller.value, 15);
      expect(notified, isTrue);
    });

    test('setValue triggers notification and updates value', () {
      final controller = AirController<int>(10, key: 'test_value');

      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.setValue(20);
      expect(controller.value, 20);
      expect(notified, isTrue);
    });

    test('setValue silent=true does not notify', () {
      final controller = AirController<int>(10, key: 'test_silent');

      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.setValue(20, silent: true);
      expect(controller.value, 20);
      expect(notified, isFalse);
    });

    test('forceNotify notifies listeners even if value is same', () {
      final controller = AirController<List<int>>([1, 2], key: 'test_list');

      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.value.add(3);
      controller.forceNotify();

      expect(controller.value, [1, 2, 3]);
      expect(notified, isTrue);
    });

    test('setValue with sourceModuleId records interaction', () {
      final mockDelegate = MockAirDelegate();
      Air.configure(delegate: mockDelegate);

      final controller = AirController<int>(0, key: 'auth.user_id');
      controller.setValue(1, sourceModuleId: 'profile');

      expect(mockDelegate.interactions, hasLength(1));
      expect(mockDelegate.interactions.first['sourceId'], 'profile');
      expect(mockDelegate.interactions.first['targetId'], 'auth');
      expect(mockDelegate.interactions.first['type'], 'data');
    });
  });

  group('Air Class Tests', () {
    setUp(() {
      Air().reset();
    });

    test('state() creates new state if not exists', () {
      final controller = Air().state<String>(
        'user_name',
        initialValue: 'Guest',
      );
      expect(controller.value, 'Guest');
      expect(controller.key, 'user_name');
    });

    test('state() reuses existing state', () {
      final controller1 = Air().state<String>(
        'user_name',
        initialValue: 'Guest',
      );
      final controller2 = Air().state<String>(
        'user_name',
        initialValue: 'SomethingElse',
      );

      expect(controller1, equals(controller2));
      expect(controller2.value, 'Guest');
    });

    test('state() throws error on type mismatch', () {
      Air().state<String>('user_name', initialValue: 'Guest');

      expect(
        () => Air().state<int>('user_name', initialValue: 0),
        throwsStateError,
      );
    });

    test('state() throws error if missing initialValue for new state', () {
      expect(() => Air().state<String>('missing_init'), throwsArgumentError);
    });

    test('dispose() removes state', () {
      Air().state<String>('temp', initialValue: 'temp');
      Air().dispose('temp');

      // Should require initialValue again as it was removed
      expect(() => Air().state<String>('temp'), throwsArgumentError);
    });

    test('debugStates returns all states', () {
      Air().state<String>('s1', initialValue: 'v1');
      Air().state<int>('s2', initialValue: 2);

      expect(Air().debugStates.length, 2);
      expect(Air().debugStates.keys, containsAll(['s1', 's2']));
    });

    test('Action Observers work correctly', () {
      final events = <String>[];
      final id = Air().addActionObserver((action, data) {
        events.add('$action:$data');
      });

      Air().pulse(action: 'test_action', params: 'data');
      expect(events, contains('test_action:data'));

      Air().removeActionObserverById(id);
      Air().pulse(action: 'test_action_2', params: 'data');
      expect(events, hasLength(1)); // No new event
    });

    test('State Observers work correctly', () {
      final changes = <String>[];
      final id = Air().addStateObserver((key, value) {
        changes.add('$key:$value');
      });

      final controller = Air().state<int>('obs_state', initialValue: 0);
      controller.value = 1;

      expect(changes, contains('obs_state:1'));

      Air().removeStateObserverById(id);
      controller.value = 2;
      expect(changes, hasLength(1)); // No new change
    });

    test('pulse delegates to AirDelegate', () {
      final mockDelegate = MockAirDelegate();
      Air.configure(delegate: mockDelegate);

      Air().pulse(
        action: 'login',
        params: {'user': 'admin'},
        sourceModuleId: 'auth_screen',
      );

      expect(mockDelegate.pulses, hasLength(1));
      final pulse = mockDelegate.pulses.first;

      // The pulse method wraps params in AirAction, so we check that
      expect(pulse['action'], 'login');
      expect(pulse['sourceId'], 'auth_screen');
      expect(pulse['params'], isA<AirAction>());
      expect((pulse['params'] as AirAction).data, {'user': 'admin'});
    });
  });
}
