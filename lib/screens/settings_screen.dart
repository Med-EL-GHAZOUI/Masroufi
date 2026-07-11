import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'phone_auth_screen.dart';
import 'settings/security_screen.dart';
import 'settings/about_screen.dart';
import 'settings/pin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            trailing: DropdownButton<Locale>(
              value: context.locale,
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  context.setLocale(newLocale);
                }
              },
              items: const [
                DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
                DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.blueGrey),
            title: Text('security'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final usePin = prefs.getBool('usePin') ?? false;

              if (usePin) {
                if (!context.mounted) return;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PinScreen(isVerifyingToChange: true),
                  ),
                );
                
                if (result == true && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SecurityScreen()),
                  );
                }
              } else {
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecurityScreen()),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.blue),
            title: Text('about_app'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
