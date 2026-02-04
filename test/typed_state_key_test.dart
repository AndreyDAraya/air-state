import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_state/air_state.dart';

// Simple concrete implementation for testing
class TestKey<T> extends AirStateKey<T> {
  const TestKey(super.key, {super.defaultValue});
}

void main() {
  group('TypedStateKey Tests', () {
    setUp(() {
      Air().reset();
    });

    test('AirStateKey equality and hashCode', () {
      const key1 = TestKey<int>('count');
      const key2 = TestKey<int>('count');
      const key3 = TestKey<int>('other');
      const key4 = TestKey<String>('count'); // Different type

      expect(key1, equals(key2));
      expect(key1.hashCode, equals(key2.hashCode));
      expect(key1, isNot(equals(key3)));
      expect(key1, isNot(equals(key4)));
    });

    test('typedGet returns default value if not set', () {
      const key = TestKey<int>('count', defaultValue: 10);
      expect(Air().typedGet(key), 10);
    });

    test('typedGet returns set value', () {
      const key = TestKey<int>('count', defaultValue: 10);
      Air().typedFlow(key, 20);
      expect(Air().typedGet(key), 20);
    });

    test('typedFlow sets value', () {
      const key = TestKey<String>('username');
      Air().typedFlow(key, 'Alice');
      expect(Air().typedGet(key), 'Alice');
    });

    test('typedExists returns correct status', () {
      const key = TestKey<int>('exists_check');
      expect(Air().typedExists(key), isFalse);

      Air().typedFlow(key, 1);
      expect(Air().typedExists(key), isTrue);
    });

    test('typedRemove removes state', () {
      const key = TestKey<int>('removable', defaultValue: 5);
      Air().typedFlow(key, 10);
      expect(Air().typedExists(key), isTrue);

      Air().typedRemove(key);
      expect(Air().typedExists(key), isFalse);

      // Should return default again/create new controller
      expect(Air().typedGet(key), 5);
    });

    test('typedController returns valid controller', () {
      const key = TestKey<int>('ctrl_check', defaultValue: 0);
      final controller = Air().typedController(key);

      expect(controller, isA<AirController<int>>());
      expect(controller.value, 0);
      expect(controller.key, 'ctrl_check');
    });

    test('AirStateKey.value getter/setter works', () {
      const key = TestKey<int>('prop_access', defaultValue: 100);

      expect(key.value, 100);

      key.value = 200;
      expect(key.value, 200);
      expect(Air().typedGet(key), 200);
    });
  });

  group('TypedStateKey Widget Builder Tests', () {
    setUp(() {
      Air().reset();
    });

    testWidgets('AirStateKey.build creates working widget', (
      WidgetTester tester,
    ) async {
      const key = TestKey<int>('widget_test', defaultValue: 0);

      await tester.pumpWidget(
        MaterialApp(home: key.build((context, value) => Text('Val: $value'))),
      );

      expect(find.text('Val: 0'), findsOneWidget);

      key.value = 5;
      await tester.pump();
      expect(find.text('Val: 5'), findsOneWidget);
    });

    testWidgets('Tuple (Key, Key).build creates working widget', (
      WidgetTester tester,
    ) async {
      const key1 = TestKey<int>('k1', defaultValue: 1);
      const key2 = TestKey<String>('k2', defaultValue: 'A');

      await tester.pumpWidget(
        MaterialApp(
          home: (key1, key2).build((context, v1, v2) => Text('$v1-$v2')),
        ),
      );

      expect(find.text('1-A'), findsOneWidget);

      key1.value = 2;
      await tester.pump();
      expect(find.text('2-A'), findsOneWidget);
    });
  });
}
