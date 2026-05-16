import 'package:flutter/material.dart';

import '../models/user_settings.dart';
import '../services/database_service.dart';

class SettingsState extends ChangeNotifier {
  UserSettings _settings = const UserSettings();
  bool _loaded = false;
  String? _lastError;

  UserSettings get settings => _settings;
  NarratorVoice get voice => _settings.narratorVoice;
  double get readingSpeed => _settings.readingSpeed;
  double get volume => _settings.volume;
  bool get reducedAnimations => _settings.reducedAnimations;
  bool get autoPlayNext => _settings.autoPlayNext;
  bool get readAlong => _settings.readAlong;
  bool get loaded => _loaded;
  String? get lastError => _lastError;

  Future<void> refresh() async {
    final resp = await DatabaseService.getSettings();
    if (resp.success && resp.data is UserSettings) {
      _settings = resp.data as UserSettings;
      _lastError = null;
    } else {
      _lastError = resp.message;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _patch(UserSettings updated) async {
    final previous = _settings;
    _settings = updated;
    notifyListeners();
    final resp = await DatabaseService.updateSettings(updated);
    if (!resp.success) {
      _settings = previous;
      _lastError = resp.message;
      notifyListeners();
    } else if (resp.data is UserSettings) {
      _settings = resp.data as UserSettings;
      notifyListeners();
    }
  }

  Future<void> setVoice(NarratorVoice v) =>
      _patch(_settings.copyWith(narratorVoice: v));

  Future<void> setReadingSpeed(double v) =>
      _patch(_settings.copyWith(readingSpeed: v));

  Future<void> setVolume(double v) =>
      _patch(_settings.copyWith(volume: v));

  Future<void> setReducedAnimations(bool v) =>
      _patch(_settings.copyWith(reducedAnimations: v));

  Future<void> setAutoPlayNext(bool v) =>
      _patch(_settings.copyWith(autoPlayNext: v));

  Future<void> setReadAlong(bool v) =>
      _patch(_settings.copyWith(readAlong: v));

  Future<bool> changePin({required String currentPin, required String newPin}) async {
    final resp = await DatabaseService.changePin(
      currentPin: currentPin,
      newPin: newPin,
    );
    if (!resp.success) {
      _lastError = resp.message;
      notifyListeners();
    }
    return resp.success;
  }

  void clear() {
    _settings = const UserSettings();
    _loaded = false;
    notifyListeners();
  }
}
