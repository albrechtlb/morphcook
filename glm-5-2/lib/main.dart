import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/corpus.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding.dart';
import 'screens/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MorphCookApp());
}

class MorphCookApp extends StatelessWidget {
  const MorphCookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _BootstrapNotifier(),
      child: Consumer<_BootstrapNotifier>(
        builder: (context, boot, _) {
          // While loading or errored, show splash/error without AppState.
          if (boot.state == _BootState.loading || boot.appState == null) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Splash(),
            );
          }
          if (boot.state == _BootState.error) {
            return const MaterialApp(home: _ErrorScreen());
          }
          // Bootstrapped: provide AppState above MaterialApp so every route
          // (including pushReplacement / pushed routes) can access it.
          return ChangeNotifierProvider<AppState>.value(
            value: boot.appState!,
            child: MaterialApp(
              title: 'MorphCook',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                scaffoldBackgroundColor: MorphColors.paper,
                colorScheme: ColorScheme.fromSeed(seedColor: MorphColors.teal, brightness: Brightness.light).copyWith(
                  primary: MorphColors.ink,
                  secondary: MorphColors.coral,
                  background: MorphColors.paper,
                  surface: MorphColors.paper,
                  onSurface: MorphColors.ink,
                ),
                fontFamily: 'Playfair Display',
                textTheme: const TextTheme(),
                appBarTheme: const AppBarTheme(backgroundColor: MorphColors.paper, elevation: 0, foregroundColor: MorphColors.ink),
                iconTheme: const IconThemeData(color: MorphColors.ink),
              ),
              home: Consumer<AppState>(
                builder: (context, app, _) => app.profile.onboardingDone
                    ? const HomeShell()
                    : const OnboardingFlow(),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _BootState { loading, ready, needsOnboarding, error }

class _BootstrapNotifier extends ChangeNotifier {
  _BootState state = _BootState.loading;
  AppState? appState;

  _BootstrapNotifier() {
    _boot();
  }

  Future<void> _boot() async {
    try {
      final corpus = await Corpus.load();
      final app = await AppState.create(corpus);
      appState = app;
      state = app.profile.onboardingDone ? _BootState.ready : _BootState.needsOnboarding;
    } catch (e, st) {
      debugPrint('boot failed: $e\n$st');
      state = _BootState.error;
    }
    notifyListeners();
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MorphColors.paper,
      body: Center(child: Text('Could not start MorphCook.', style: TextStyle(color: MorphColors.ink))),
    );
  }
}
