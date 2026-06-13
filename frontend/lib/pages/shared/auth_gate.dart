import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../caregiver/caregiver_shell.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStatus? _lastStatus;
  String? _lastCaregiverId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final caregiverId = auth.user?.caregiverId;

    // Fire the cross-state sync after the current frame paints — running
    // it synchronously here would call notifyListeners on other states
    // mid-build, which Provider asserts against.
    if (auth.status != _lastStatus || caregiverId != _lastCaregiverId) {
      _lastStatus = auth.status;
      _lastCaregiverId = caregiverId;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _onAuthChanged(auth.status));
    }

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.signedOut:
        return const LoginPage();
      case AuthStatus.signedIn:
        return const CaregiverShell();
    }
  }
}
