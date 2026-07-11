import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _usePin = false;
  bool _useBiometrics = false;

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
            title: const Text('Code PIN'), // Will translate later
            subtitle: const Text('Activer un code PIN au démarrage'),
            value: _usePin,
            onChanged: (val) {
              setState(() => _usePin = val);
            },
            secondary: const Icon(Icons.password, color: Colors.blueGrey),
          ),
          SwitchListTile(
            title: const Text('Biométrie'),
            subtitle: const Text('Utiliser l\'empreinte digitale'),
            value: _useBiometrics,
            onChanged: (val) {
              setState(() => _useBiometrics = val);
            },
            secondary: const Icon(Icons.fingerprint, color: Colors.blueGrey),
          ),
          const SizedBox(height: 24),
          if (_usePin)
            ElevatedButton(
              onPressed: () {
                // TODO: Set up PIN
              },
              child: const Text('Configurer le code PIN'),
            ),
        ],
      ),
    );
  }
}
