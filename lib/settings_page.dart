import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: onToggleTheme,
            color: Colors.white,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (_) => onToggleTheme(),
              activeColor: const Color(0xFF009688),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: const Color(0xFF009688),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: const Text('English'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('About'),
                  content: const Text('Diary App v1.0.0'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}