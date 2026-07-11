import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'phone_auth_screen.dart';

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
            leading: const Icon(Icons.sync),
            title: const Text('Synchronisation et Sauvegarde'),
            subtitle: Text(
              authService.isAuthenticated
                  ? 'Connecté (Sauvegarde active)'
                  : 'Non connecté, appuyez pour lier votre numéro',
            ),
            trailing: authService.isAuthenticated
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PhoneAuthScreen(),
                        ),
                      );
                    },
                    child: const Text('Se connecter'),
                  ),
            onTap: () {
              if (!authService.isAuthenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
