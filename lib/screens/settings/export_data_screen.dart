import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ExportDataScreen extends StatelessWidget {
  const ExportDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('export_data'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choisissez le format d\'exportation de vos données financières :',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
              title: const Text('Exporter en PDF', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Génère un rapport visuel de vos transactions'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green, size: 40),
              title: const Text('Exporter en Excel (CSV)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Idéal pour analyser vos données sur ordinateur'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
