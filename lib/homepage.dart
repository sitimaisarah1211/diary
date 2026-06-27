// homepage.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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