import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  String _themeMode = 'system';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('theme'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RadioListTile<String>(
            title: const Text('Clair'),
            secondary: const Icon(Icons.wb_sunny, color: Colors.orange),
            value: 'light',
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() => _themeMode = value!);
            },
          ),
          RadioListTile<String>(
            title: const Text('Sombre'),
            secondary: const Icon(Icons.nights_stay, color: Colors.indigo),
            value: 'dark',
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() => _themeMode = value!);
            },
          ),
          RadioListTile<String>(
            title: const Text('Automatique (Système)'),
            secondary: const Icon(Icons.settings_system_daydream, color: Colors.grey),
            value: 'system',
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() => _themeMode = value!);
            },
          ),
        ],
      ),
    );
  }
}
