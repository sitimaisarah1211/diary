import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'sql_helper.dart';

part 'homepage_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
    required this.isDarkMode,
    required this.onToggleTheme,
  }) : super(key: key);

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  HomePageState createState() => HomePageState();
}