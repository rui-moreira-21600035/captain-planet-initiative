import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_app/features/launcher/launcher_page.dart';

void main() {
  // testWidgets('Hub App page launcher test', (WidgetTester tester) async {
  //   // Build our app and trigger a frame.
  //   await tester.pumpWidget(const HubApp());

  //   // Verify that our counter starts at 0.
  //   expect(find.text('Hub de Mini-jogos'), findsOneWidget);
  //   expect(find.text('Eco Sort'), findsOneWidget);
  //   expect(find.text('Clica no contentor certo para cada item.'), findsOneWidget);
  //   expect(find.text(''), findsNothing);
  //   await tester.pump();
  //   await tester.tap(find.byKey(Key('eco_sort')));
    

  //   // Tap the '+' icon and trigger a frame.
  //   // await tester.tap(find.byIcon(Icons.add));
  //   // await tester.pump();
  // debugPrint("Test Completed.");
  // });
}

class HubApp extends StatelessWidget {
  const HubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minigames Hub',
      theme: ThemeData(useMaterial3: true),
      home: const LauncherPage(),
    );
  }
}
