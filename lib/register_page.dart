import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';
import 'localization.dart';

class RegisterPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLanguageChange;

  const RegisterPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLanguageChange,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  String _errorMessage = "";
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (_passCtrl.text.trim() != _confirmCtrl.text.trim()) {
      setState(() => _errorMessage = "Passwords do not match");
      return;
    }
    if (_passCtrl.text.trim().length < 6) {
      setState(() => _errorMessage = "Password must be at least 6 characters");
      return;
    }
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
            onLanguageChange: widget.onLanguageChange,
            customTitle: "Diary",
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = "Registration failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.translate('register')),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
            color: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.translate('email'),
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: AppLocalizations.translate('password'),
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: AppLocalizations.translate('confirm_password'),
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                AppLocalizations.translate('register'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.translate('already_account')),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}