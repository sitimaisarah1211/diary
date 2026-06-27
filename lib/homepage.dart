import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';

// penting: declare part
part 'homepage_state.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final String customTitle;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.customTitle = "Diary",
  });

  @override
  State<HomePage> createState() => HomePageState();
}
