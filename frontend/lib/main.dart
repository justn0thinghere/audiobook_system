import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Routing
import 'navigation/app_navigation_service.dart';
import 'navigation/app_routes.dart';

// State
import 'state/auth_state.dart';
import 'state/profiles_state.dart';
import 'state/settings_state.dart';

// Theme
import 'theme/app_theme.dart';

// Pages
import 'pages/shared/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AudiobookApp());
}

class AudiobookApp extends StatelessWidget {
  const AudiobookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()..bootstrap()),
        ChangeNotifierProvider(create: (_) => ProfilesState()),
        ChangeNotifierProvider(create: (_) => SettingsState()),
      ],
      child: MaterialApp(
        title: 'Audiobook for Autism',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        navigatorKey: AppNavigationService.navigatorKey,
        scaffoldMessengerKey: AppNavigationService.scaffoldMessengerKey,
        home: const _SessionScopedLoader(),
        routes: AppRoutes.staticRoutes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

/// Reacts to AuthState changes — when the caregiver signs in, hydrate
/// profiles + settings from the API; on sign-out, clear them.
class _SessionScopedLoader extends StatefulWidget {
  const _SessionScopedLoader();

  @override
  State<_SessionScopedLoader> createState() => _SessionScopedLoaderState();
}

class _SessionScopedLoaderState extends State<_SessionScopedLoader> {
  AuthStatus? _lastStatus;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.status != _lastStatus) {
      _lastStatus = auth.status;
      WidgetsBinding.instance.addPostFrameCallback((_) => _onStatusChanged(auth.status));
    }
    return const AuthGate();
  }

  void _onStatusChanged(AuthStatus status) {
    if (!mounted) return;
    if (status == AuthStatus.signedIn) {
      context.read<ProfilesState>().refresh();
      context.read<SettingsState>().refresh();
    } else if (status == AuthStatus.signedOut) {
      context.read<ProfilesState>().clear();
      context.read<SettingsState>().clear();
    }
  }
}
