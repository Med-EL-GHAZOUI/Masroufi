import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings/security_screen.dart';
import 'settings/about_screen.dart';
import 'settings/pin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient Header
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B4E3B), Color(0xFF0077B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'settings'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance for back button
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            Card(
              elevation: 0,
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildSettingsItem(
                      context: context,
                      icon: Icons.language,
                      title: 'language'.tr(),
                      iconColor: Colors.blue,
                      trailing: DropdownButton<Locale>(
                        value: context.locale,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
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
                    const Divider(height: 1, indent: 60, endIndent: 20),
                    const SizedBox(height: 8),
                    _buildSettingsItem(
                      context: context,
                      icon: Icons.security,
                      title: 'security'.tr(),
                      iconColor: Colors.orange,
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
                    const Divider(height: 1, indent: 60, endIndent: 20),
                    const SizedBox(height: 8),
                    _buildSettingsItem(
                      context: context,
                      icon: Icons.info_outline,
                      title: 'about_app'.tr(),
                      iconColor: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AboutScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
      ],
      ),
    );
  }
}
