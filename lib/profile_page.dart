import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'localization.dart';

class ProfilePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLanguageChange;

  const ProfilePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLanguageChange,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameCtrl = TextEditingController();
  bool _isEditing = false;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _displayName = user?.displayName ?? user?.email ?? 'User';
    _nameCtrl.text = _displayName;
  }

  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.updateDisplayName(_nameCtrl.text.trim());
      await user.reload();
      setState(() {
        _displayName = user.displayName ?? _nameCtrl.text.trim();
        _isEditing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.translate('profile')),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
            color: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF009688),
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            if (!_isEditing) ...[
              Text(
                _displayName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'No email',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit),
                label: Text(AppLocalizations.translate('edit_profile')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                ),
              ),
            ] else ...[
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: AppLocalizations.translate('display_name'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _nameCtrl.text = _displayName;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: Text(AppLocalizations.translate('cancel')),
                  ),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                    ),
                    child: Text(AppLocalizations.translate('save')),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(AppLocalizations.translate('back')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
              ),
            ),
          ],
        ),
      ),
    );
  }
}