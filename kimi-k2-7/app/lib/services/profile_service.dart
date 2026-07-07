import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';

class ProfileService extends ChangeNotifier {
  static const _key = 'morphcook_profile';
  static const _onboardedKey = 'morphcook_onboarded';

  ProfileService();

  Profile? _profile;
  bool _onboarded = false;

  Profile get profile => _profile ?? Profile();

  bool get onboarded => _onboarded;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _profile = Profile.fromMap(jsonDecode(raw));
      } catch (_) {
        _profile = Profile();
      }
    } else {
      _profile = Profile();
    }
    _onboarded = prefs.getBool(_onboardedKey) ?? false;
    notifyListeners();
  }

  Future<void> saveProfile(Profile updated) async {
    _profile = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(updated.toMap()));
    notifyListeners();
  }

  Future<void> setOnboarded(bool value) async {
    _onboarded = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, value);
    notifyListeners();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_onboardedKey);
    _profile = Profile();
    _onboarded = false;
    notifyListeners();
  }
}
