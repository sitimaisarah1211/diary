import 'package:flutter/material.dart';
import 'localization.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLanguageChange;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLanguageChange,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = AppLocalizations.currentLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.translate('settings')),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text(widget.isDarkMode ? AppLocalizations.translate('dark_mode') : AppLocalizations.translate('light_mode')),
            trailing: Switch(
              value: widget.isDarkMode,
              onChanged: (_) => widget.onToggleTheme(),
              activeColor: const Color(0xFF009688),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.translate('language')),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English 🇬🇧')),
                DropdownMenuItem(value: 'ms', child: Text('Malay 🇲🇾')),
              ],
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                  await AppLocalizations.setLanguage(value);
                  widget.onLanguageChange();
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(AppLocalizations.translate('about')),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(AppLocalizations.translate('about')),
                  content: Text(AppLocalizations.translate('version')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.translate('ok')),
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