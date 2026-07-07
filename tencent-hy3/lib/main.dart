import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/data_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MorphCookApp());
}

class MorphCookApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DataProvider()..initialize(),
      child: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          return MaterialApp(
            title: 'MorphCook',
            theme: AppTheme.lightTheme,
            home: dataProvider.isLoaded
                ? (dataProvider.isOnboardingComplete
                    ? HomeScreen()
                    : OnboardingScreen())
                : SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MorphCook',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: AppTheme.inkBlack,
              strokeWidth: 1,
            ),
          ],
        ),
      ),
    );
  }
}
