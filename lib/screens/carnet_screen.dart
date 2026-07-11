import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/credit_provider.dart';
import 'add_person_screen.dart';
import 'person_details_screen.dart';

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
      appBar: AppBar(title: Text('carnet'.tr()), centerTitle: true),
      body: Column(
        children: [
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
                        onPressed: () {},
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
                        onPressed: () {},
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
                    child: Text(person.name[0].toUpperCase()),
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
}
