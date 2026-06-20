import 'package:flutter/material.dart';
import 'login_page.dart'; // Tukar ikut struktur folder projek awak jika perlu

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true; // Set default terus dark mode atau false untuk light mode

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siti Maisarah Diary',
      debugShowCheckedModeBanner: false,
      // Paksa tema sistem ikut variable _isDarkMode kita
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF212121),
      ),
      home: LoginPage(
        isDarkMode: _isDarkMode,
        onToggleTheme: () {
          // WAJIB ADA setState di sini supaya satu app bertukar warna!
          setState(() {
            _isDarkMode = !_isDarkMode;
          });
        },
      ),
    );
  }
}