import 'package:flutter/material.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const SplashScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginPage(
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFF009688),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.book,
                size: 80,
                color: Color(0xFF009688),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'My Diary',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '✨ Your Personal Journal ✨',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.white70,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: isDark ? Colors.teal : Colors.white,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}