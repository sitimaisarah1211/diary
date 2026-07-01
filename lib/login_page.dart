import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';
import 'register_page.dart';
import 'settings_page.dart';
import 'localization.dart';

class LoginPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLanguageChange;

  const LoginPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLanguageChange,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  String _errorMessage = "";
  bool _obscurePassword = true;

  // The specific email for biometric login
  static const String BIOMETRIC_EMAIL = "sitimaisarahyushainey@gmail.com";
  static const String PASSWORD_STORAGE_KEY = "biometric_password";

  @override
  void initState() {
    super.initState();
    // Pre-fill the email field with the biometric email
    _emailCtrl.text = BIOMETRIC_EMAIL;
    _loadSavedPassword();
  }

  Future<void> _loadSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPass = prefs.getString(PASSWORD_STORAGE_KEY);
    if (savedPass != null) {
      _passCtrl.text = savedPass;
    }
  }

  Future<void> _savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PASSWORD_STORAGE_KEY, password);
  }

  Future<void> _loginWithEmail() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      // Save the password for future biometric use
      await _savePassword(_passCtrl.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
            onLanguageChange: widget.onLanguageChange,
            customTitle: "${_emailCtrl.text.split('@')[0]} Diary",
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = "Login failed: $e");
    }
  }

  Future<void> _loginWithFingerprint() async {
    try {
      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate with fingerprint to login as $BIOMETRIC_EMAIL',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (didAuthenticate) {
        // Try to sign in with saved password
        final prefs = await SharedPreferences.getInstance();
        String? savedPass = prefs.getString(PASSWORD_STORAGE_KEY);
        if (savedPass == null || savedPass.isEmpty) {
          // If no saved password, ask user to enter it once
          String? enteredPass = await _promptForPassword(context);
          if (enteredPass != null && enteredPass.isNotEmpty) {
            savedPass = enteredPass;
            await _savePassword(savedPass);
          } else {
            setState(() => _errorMessage = "Password required for biometric login.");
            return;
          }
        }
        // Now sign in with the saved password
        try {
          await _auth.signInWithEmailAndPassword(
            email: BIOMETRIC_EMAIL,
            password: savedPass,
          );
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                isDarkMode: widget.isDarkMode,
                onToggleTheme: widget.onToggleTheme,
                onLanguageChange: widget.onLanguageChange,
                customTitle: "${BIOMETRIC_EMAIL.split('@')[0]} Diary",
              ),
            ),
          );
        } catch (e) {
          // If password is wrong, clear it and ask again
          await _savePassword('');
          setState(() => _errorMessage = "Saved password is incorrect. Please login with email to update.");
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Fingerprint login failed: $e");
    }
  }

  Future<String?> _promptForPassword(BuildContext context) async {
    final TextEditingController passCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password for biometric login',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, passCtrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.translate('login')),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isDarkMode: widget.isDarkMode,
                    onToggleTheme: widget.onToggleTheme,
                    onLanguageChange: widget.onLanguageChange,
                  ),
                ),
              );
            },
            color: Colors.white,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF009688).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.book, size: 60, color: Color(0xFF009688)),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.translate('welcome_back'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.translate('sign_in'),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.translate('email'),
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
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
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginWithEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                AppLocalizations.translate('login'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.fingerprint),
              label: Text('Login as $BIOMETRIC_EMAIL'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: Color(0xFF009688)),
              ),
              onPressed: _loginWithFingerprint,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterPage(
                      isDarkMode: widget.isDarkMode,
                      onToggleTheme: widget.onToggleTheme,
                      onLanguageChange: widget.onLanguageChange,
                    ),
                  ),
                );
              },
              child: Text(AppLocalizations.translate('no_account')),
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