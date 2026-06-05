import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Routing
import 'navigation/app_navigation_service.dart';
import 'navigation/app_routes.dart';

// State
import 'state/auth_state.dart';
import 'state/language_state.dart';
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
        ChangeNotifierProvider(create: (_) => LanguageState()..bootstrap()),
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

// Reacts to AuthState changes — when the caregiver signs in, hydrate
// profiles + settings from the API; on sign-out, clear them.
class _SessionScopedLoader extends StatefulWidget {
  const _SessionScopedLoader();

  @override
  State<_SessionScopedLoader> createState() => _SessionScopedLoaderState();
}

class _SessionScopedLoaderState extends State<_SessionScopedLoader> {
  AuthStatus? _lastStatus;
  String? _lastCaregiverId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final caregiverId = auth.user?.caregiverId;
    // Re-scope on status changes AND when the signed-in caregiver changes —
    // so switching to a different account never shows the previous
    // caregiver's child profiles or settings.
    if (auth.status != _lastStatus || caregiverId != _lastCaregiverId) {
      _lastStatus = auth.status;
      _lastCaregiverId = caregiverId;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _onAuthChanged(auth.status));
    }
    return const AuthGate();
  }

  void _onAuthChanged(AuthStatus status) {
    if (!mounted) return;
    final profiles = context.read<ProfilesState>();
    final settings = context.read<SettingsState>();
    if (status == AuthStatus.signedIn) {
      // refresh() clears stale data only when the caregiver actually changes,
      // and keeps a good list if the fetch hiccups — so a caregiver's children
      // never vanish on sign-in. Settings are per-child and load on demand.
      final caregiverId = context.read<AuthState>().user?.caregiverId;
      settings.clear();
      profiles.refresh(caregiverId: caregiverId);
    } else if (status == AuthStatus.signedOut) {
      profiles.clear();
      settings.clear();
    }
  }
}
