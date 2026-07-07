import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphcook/services/profile_service.dart';
import 'package:morphcook/ui/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Onboarding renders language page', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ProfileService>(
          create: (_) => ProfileService(),
          child: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
  });
}
