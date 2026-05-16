import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../services/database_service.dart';

class ProfilesState extends ChangeNotifier {
  List<ChildProfile> _profiles = const [];
  ChildProfile? _activeProfile;
  bool _loading = false;
  String? _lastError;

  List<ChildProfile> get profiles => List.unmodifiable(_profiles);
  ChildProfile? get activeProfile => _activeProfile;
  bool get loading => _loading;
  String? get lastError => _lastError;

  int get totalChildren => _profiles.length;
  int get totalListeningMinutes =>
      _profiles.fold(0, (sum, p) => sum + p.listeningMinutes);
  int get averageEngagement => _profiles.isEmpty ? 0 : 87;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    final resp = await DatabaseService.listChildProfiles();
    if (resp.success && resp.data is List<ChildProfile>) {
      _profiles = resp.data as List<ChildProfile>;
      _lastError = null;
    } else {
      _lastError = resp.message;
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> addProfile({
    required String name,
    required int age,
    required String avatarEmoji,
    required String avatarColorHex,
    String? favoriteGenre,
  }) async {
    final resp = await DatabaseService.createChildProfile(
      name: name,
      age: age,
      avatarEmoji: avatarEmoji,
      avatarColorHex: avatarColorHex,
      favoriteGenre: favoriteGenre,
    );
    if (resp.success && resp.data is ChildProfile) {
      _profiles = [..._profiles, resp.data as ChildProfile];
      notifyListeners();
      return true;
    }
    _lastError = resp.message;
    notifyListeners();
    return false;
  }

  Future<bool> deleteProfile(String childId) async {
    final resp = await DatabaseService.deleteChildProfile(childId);
    if (resp.success) {
      _profiles = _profiles.where((p) => p.childId != childId).toList();
      if (_activeProfile?.childId == childId) _activeProfile = null;
      notifyListeners();
      return true;
    }
    _lastError = resp.message;
    notifyListeners();
    return false;
  }

  void enterChildMode(ChildProfile profile) {
    _activeProfile = profile;
    notifyListeners();
  }

  void exitChildMode() {
    _activeProfile = null;
    notifyListeners();
  }

  void clear() {
    _profiles = const [];
    _activeProfile = null;
    notifyListeners();
  }
}
