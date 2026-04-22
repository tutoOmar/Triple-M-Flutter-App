import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mi_app/app/app.dart';
import 'package:mi_app/app/router.dart';

void main() {
  testWidgets('MiApp renders with an injected router', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Inicio')),
          ),
        ),
      ],
    );

    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(router)],
        child: const MiApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
  });
}
