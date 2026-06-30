// localization.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  static const String _langKey = 'app_language';
  static const String defaultLanguage = 'en';

  static String currentLanguage = defaultLanguage;

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    currentLanguage = prefs.getString(_langKey) ?? defaultLanguage;
  }

  static Future<void> setLanguage(String lang) async {
    currentLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
  }

  static String translate(String key) {
    final translations = {
      'en': {
        'app_title': 'My Diary',
        'welcome_back': 'Welcome Back!',
        'sign_in': 'Sign in to continue to your diary',
        'email': 'Email',
        'password': 'Password',
        'login': 'Login',
        'fingerprint': 'Login with Fingerprint',
        'no_account': "Don't have an account? Create new account",
        'register': 'Register',
        'confirm_password': 'Confirm Password',
        'already_account': 'Already have an account? Login',
        'create_diary': 'Create New Diary',
        'how_feeling': 'How are you feeling?',
        'whats_mind': "What's on your mind?",
        'save_diary': 'Save Diary',
        'no_entries': 'No diary entries yet',
        'start_writing': 'Start writing your first entry above ✨',
        'profile': 'Profile',
        'settings': 'Settings',
        'search_diary': 'Search Diary',
        'logout': 'Logout',
        'light_mode': 'Light Mode',
        'dark_mode': 'Dark Mode',
        'edit_profile': 'Edit Profile',
        'display_name': 'Display Name',
        'save': 'Save',
        'back': 'Back',
        'language': 'Language',
        'about': 'About',
        'version': 'Diary App v1.0.0',
        'ok': 'OK',
        'delete_title': 'Delete Entry',
        'delete_confirm': 'Are you sure you want to delete this diary entry?',
        'yes': 'Yes',
        'no': 'No',
        'edit_diary': 'Edit Diary',
        'cancel': 'Cancel',
        'update': 'Update',
        'description': 'Description',
        'feeling': 'Feeling',
        'location_disabled': 'Location disabled',
        'permission_denied': 'Permission denied',
        'permission_forever': 'Permission denied forever',
        'unable_location': 'Unable to get location',
        'weather_unavailable': 'Weather unavailable',
        'entry_deleted': 'Entry deleted',
        'entry_restored': 'Entry restored!',
        'entry_updated': 'Entry updated!',
        'diary_saved': 'Diary saved successfully!',
        'speech_unavailable': 'Speech recognition not available',
        'search_hint': 'Search diary...',
        'no_match': 'No entries match your search',
        'error_loading': 'Error loading entries',
        'please_enter_description': 'Please enter a description',
      },
      'ms': {
        'app_title': 'Diari Saya',
        'welcome_back': 'Selamat Kembali!',
        'sign_in': 'Log masuk untuk terus ke diari anda',
        'email': 'Emel',
        'password': 'Kata Laluan',
        'login': 'Log Masuk',
        'fingerprint': 'Log Masuk dengan Cap Jari',
        'no_account': "Tiada akaun? Cipta akaun baru",
        'register': 'Daftar',
        'confirm_password': 'Sahkan Kata Laluan',
        'already_account': 'Sudah ada akaun? Log masuk',
        'create_diary': 'Cipta Diari Baru',
        'how_feeling': 'Apa perasaan anda?',
        'whats_mind': 'Apa yang ada di fikiran?',
        'save_diary': 'Simpan Diari',
        'no_entries': 'Tiada entri diari lagi',
        'start_writing': 'Mula menulis entri pertama di atas ✨',
        'profile': 'Profil',
        'settings': 'Tetapan',
        'search_diary': 'Cari Diari',
        'logout': 'Log Keluar',
        'light_mode': 'Mod Terang',
        'dark_mode': 'Mod Gelap',
        'edit_profile': 'Sunting Profil',
        'display_name': 'Nama Paparan',
        'save': 'Simpan',
        'back': 'Kembali',
        'language': 'Bahasa',
        'about': 'Perihal',
        'version': 'Aplikasi Diari v1.0.0',
        'ok': 'OK',
        'delete_title': 'Padam Entri',
        'delete_confirm': 'Adakah anda pasti mahu memadam entri ini?',
        'yes': 'Ya',
        'no': 'Tidak',
        'edit_diary': 'Sunting Diari',
        'cancel': 'Batal',
        'update': 'Kemas Kini',
        'description': 'Keterangan',
        'feeling': 'Perasaan',
        'location_disabled': 'Lokasi dilumpuhkan',
        'permission_denied': 'Keizinan ditolak',
        'permission_forever': 'Keizinan ditolak selama-lamanya',
        'unable_location': 'Tidak dapat mengesan lokasi',
        'weather_unavailable': 'Cuaca tidak tersedia',
        'entry_deleted': 'Entri dipadam',
        'entry_restored': 'Entri dipulihkan!',
        'entry_updated': 'Entri dikemas kini!',
        'diary_saved': 'Diari berjaya disimpan!',
        'speech_unavailable': 'Pengecaman suara tidak tersedia',
        'search_hint': 'Cari diari...',
        'no_match': 'Tiada entri yang sepadan',
        'error_loading': 'Ralat memuatkan entri',
        'please_enter_description': 'Sila masukkan keterangan',
      },
    };

    return translations[currentLanguage]?[key] ?? key;
  }
}