import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pin_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _usePin = false;
  bool _useBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usePin = prefs.getBool('usePin') ?? false;
      _useBiometrics = prefs.getBool('useBiometrics') ?? false;
    });
  }

  Future<void> _togglePin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (value) {
      // User wants to turn ON PIN
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PinScreen(isSettingPin: true)),
      );
      if (result == true) {
        setState(() {
          _usePin = true;
        });
      }
    } else {
      // User wants to turn OFF PIN. Need to verify first!
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PinScreen(isVerifyingToChange: true)),
      );
      if (result == true) {
        await prefs.setBool('usePin', false);
        await prefs.remove('appPin'); // Remove saved PIN
        // If PIN is off, turn off biometrics too
        await prefs.setBool('useBiometrics', false);
        setState(() {
          _usePin = false;
          _useBiometrics = false;
        });
      }
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (!_usePin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord activer un code PIN')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    // Verify PIN before changing biometrics
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PinScreen(isVerifyingToChange: true)),
    );
    
    if (result == true) {
      await prefs.setBool('useBiometrics', value);
      setState(() {
        _useBiometrics = value;
      });
    }
  }

  Future<void> _changePin() async {
    // Verify old PIN first
    final result1 = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PinScreen(isVerifyingToChange: true)),
    );
    if (result1 == true) {
      // Set new PIN
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PinScreen(isSettingPin: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('security'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Code PIN'),
            subtitle: const Text('Activer un code PIN au démarrage'),
            value: _usePin,
            onChanged: _togglePin,
            secondary: const Icon(Icons.password, color: Colors.blueGrey),
          ),
          SwitchListTile(
            title: const Text('Biométrie'),
            subtitle: const Text('Utiliser l\'empreinte digitale'),
            value: _useBiometrics,
            onChanged: _toggleBiometrics,
            secondary: const Icon(Icons.fingerprint, color: Colors.blueGrey),
          ),
          const SizedBox(height: 24),
          if (_usePin)
            ElevatedButton(
              onPressed: _changePin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Modifier le code PIN', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}
