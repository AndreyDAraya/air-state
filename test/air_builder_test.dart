import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_state/air_state.dart';
import 'mock_air_delegate.dart';

void main() {
  group('AirBuilder Tests', () {
    setUp(() {
      Air().reset();
    });

    testWidgets('AirBuilder rebuilds when state changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AirBuilder<int>(
            stateKey: 'counter',
            initialValue: 0,
            builder: (context, value) {
              return Text('Count: $value');
            },
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      Air().state<int>('counter').value = 1;
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets(
      'AirBuilder records interaction if callerModuleId is provided',
      (WidgetTester tester) async {
        final mockDelegate = MockAirDelegate();
        Air.configure(delegate: mockDelegate);

        await tester.pumpWidget(
          MaterialApp(
            home: AirBuilder<String>(
              stateKey: 'auth.user',
              initialValue: 'Alice',
              callerModuleId: 'profile',
              builder: (context, value) {
                return Text('User: $value');
              },
            ),
          ),
        );

        // Interaction is recorded during build/listener setup
        expect(mockDelegate.interactions, hasLength(1));
        expect(
          mockDelegate.interactions.first['sourceId'],
          'auth',
        ); // Target data
        expect(
          mockDelegate.interactions.first['targetId'],
          'profile',
        ); // Caller
      },
    );

    testWidgets('AirBuilder2 rebuilds when either state changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AirBuilder2<int, String>(
            key1: 'n1',
            initial1: 0,
            key2: 's1',
            initial2: 'A',
            builder: (context, v1, v2) {
              return Text('$v1-$v2');
            },
          ),
        ),
      );

      expect(find.text('0-A'), findsOneWidget);

      Air().state<int>('n1').value = 1;
      await tester.pump();
      expect(find.text('1-A'), findsOneWidget);

      Air().state<String>('s1').value = 'B';
      await tester.pump();
      expect(find.text('1-B'), findsOneWidget);
    });

    testWidgets('AirBuilder3 rebuilds when any state changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AirBuilder3<int, String, bool>(
            key1: 'n1',
            initial1: 0,
            key2: 's1',
            initial2: 'A',
            key3: 'b1',
            initial3: true,
            builder: (context, v1, v2, v3) {
              return Text('$v1-$v2-$v3');
            },
          ),
        ),
      );

      expect(find.text('0-A-true'), findsOneWidget);

      Air().state<int>('n1').value = 1;
      await tester.pump();
      expect(find.text('1-A-true'), findsOneWidget);

      Air().state<String>('s1').value = 'B';
      await tester.pump();
      expect(find.text('1-B-true'), findsOneWidget);

      Air().state<bool>('b1').value = false;
      await tester.pump();
      expect(find.text('1-B-false'), findsOneWidget);
    });
  });

  group('AirView Tests', () {
    setUp(() {
      Air().reset();
    });

    testWidgets('AirView tracks dependencies and rebuilds', (
      WidgetTester tester,
    ) async {
      // Initialize states
      final userState = Air().state<String>('user', initialValue: 'Alice');
      final scoreState = Air().state<int>('score', initialValue: 100);

      await tester.pumpWidget(
        MaterialApp(
          home: AirView((context) {
            return Column(
              children: [
                Text('User: ${userState.value}'),
                Text('Score: ${scoreState.value}'),
              ],
            );
          }),
        ),
      );

      expect(find.text('User: Alice'), findsOneWidget);
      expect(find.text('Score: 100'), findsOneWidget);

      // Update user
      userState.value = 'Bob';
      await tester.pump();
      expect(find.text('User: Bob'), findsOneWidget);

      // Update score
      scoreState.value = 200;
      await tester.pump();
      expect(find.text('Score: 200'), findsOneWidget);
    });

    testWidgets('AirView handles conditional dependencies', (
      WidgetTester tester,
    ) async {
      final toggleState = Air().state<bool>('toggle', initialValue: true);
      final valueA = Air().state<String>('valA', initialValue: 'A');
      final valueB = Air().state<String>('valB', initialValue: 'B');

      await tester.pumpWidget(
        MaterialApp(
          home: AirView((context) {
            if (toggleState.value) {
              return Text('Value: ${valueA.value}');
            } else {
              return Text('Value: ${valueB.value}');
            }
          }),
        ),
      );

      expect(find.text('Value: A'), findsOneWidget);

      // Switch toggle to false
      toggleState.value = false;
      await tester.pump();
      expect(find.text('Value: B'), findsOneWidget);

      // Verify B updates
      valueB.value = 'BUpdated';
      await tester.pump();
      expect(find.text('Value: BUpdated'), findsOneWidget);
    });
  });
}
