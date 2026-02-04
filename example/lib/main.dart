import 'package:flutter/material.dart';
import 'package:air_state/air_state.dart';

void main() {
  runApp(const MaterialApp(home: AirStateExample()));
}

// Define typed keys to avoid magic strings
const counterKey = SimpleStateKey<int>('counter', defaultValue: 0);

class AirStateExample extends StatelessWidget {
  const AirStateExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Air State Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AirView((context) {
              return Text(
                'You have pushed the button this many times: ${counterKey.value}',
              );
            }),
            // Build widget directly from the key
            counterKey.build((context, value) {
              return Text(
                'Other way to show value: $value',
                style: Theme.of(context).textTheme.headlineMedium,
              );
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Update value directly via key
          counterKey.value++;
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
