import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/credit_provider.dart';
import '../services/export_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_person_screen.dart';
import 'person_details_screen.dart';
import '../widgets/premium_header.dart';

class CarnetScreen extends StatefulWidget {
  const CarnetScreen({super.key});

  @override
  State<CarnetScreen> createState() => _CarnetScreenState();
}

class _CarnetScreenState extends State<CarnetScreen> {
  bool _isClientView = true;

  @override
  Widget build(BuildContext context) {
    final creditProvider = Provider.of<CreditProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          PremiumHeader(
            title: 'carnet'.tr(),
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ),
          // Segmented Control (Client / Supplier)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isClientView
                          ? Theme.of(context).primaryColor
                          : Colors.grey[200],
                      foregroundColor: _isClientView
                          ? Colors.white
                          : Colors.black,
                    ),
                    onPressed: () => setState(() => _isClientView = true),
                    child: Text('clients'.tr()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isClientView
                          ? Theme.of(context).primaryColor
                          : Colors.grey[200],
                      foregroundColor: !_isClientView
                          ? Colors.white
                          : Colors.black,
                    ),
                    onPressed: () => setState(() => _isClientView = false),
                    child: Text('suppliers'.tr()),
                  ),
                ),
              ],
            ),
          ),

          // Summary Card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Action buttons
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          ExportService.exportCarnetToPdf(context, creditProvider, _isClientView);
                        },
                      ),
                      Text(
                        'reports'.tr(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_active,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          _showPaymentReminders(context, creditProvider);
                        },
                      ),
                      Text(
                        'payment_reminder'.tr(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Balances
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'i_received'.tr(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${creditProvider.getTotalReceived(_isClientView).toStringAsFixed(2)} DH',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'i_gave'.tr(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${creditProvider.getTotalGiven(_isClientView).toStringAsFixed(2)} DH',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'search'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              itemCount: creditProvider.persons
                  .where((p) => p.isClient == _isClientView)
                  .length,
              itemBuilder: (context, index) {
                final person = creditProvider.persons
                    .where((p) => p.isClient == _isClientView)
                    .toList()[index];
                final balance = creditProvider.getPersonBalance(person.id);
                // Positive balance means we received more than gave? Or maybe the opposite for ledger.
                // Let's just show it.
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(person.name.isNotEmpty ? person.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(person.name),
                  subtitle: Text(person.phone ?? ''),
                  trailing: Text(
                    '${balance.toStringAsFixed(2)} DH',
                    style: TextStyle(
                      color: balance >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonDetailsScreen(person: person),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPersonScreen(isClient: _isClientView),
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: Text(_isClientView ? 'add_client'.tr() : 'add_supplier'.tr()),
      ),
    );
  }

  Future<void> _showPaymentReminders(BuildContext context, CreditProvider provider) async {
    final debtors = provider.persons.where((p) {
      if (p.isClient != _isClientView) return false;
      final balance = provider.getPersonBalance(p.id);
      return balance != 0;
    }).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        if (debtors.isEmpty) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: Text('no_data'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
          );
        }
        return Column(
          children: [
            const SizedBox(height: 16),
            Text('payment_reminder'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: debtors.length,
                itemBuilder: (context, index) {
                  final person = debtors[index];
                  final balance = provider.getPersonBalance(person.id);
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(person.name),
                    subtitle: Text('${balance.toStringAsFixed(2)} DH', style: const TextStyle(color: Colors.red)),
                    trailing: IconButton(
                      icon: const Icon(Icons.send, color: Colors.green),
                      onPressed: () async {
                        final String message = "Bonjour ${person.name},\nCeci est un rappel amical concernant votre solde de ${balance.abs().toStringAsFixed(2)} DH. Merci d'avance !";
                        final String encodedMessage = Uri.encodeComponent(message);
                        final String url = "https://wa.me/${person.phone}?text=$encodedMessage";
                        
                        final Uri uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp.')),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
