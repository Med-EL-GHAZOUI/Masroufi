import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: provider.accounts.length,
        itemBuilder: (context, index) {
          final account = provider.accounts[index];
          IconData iconData = Icons.account_balance_wallet;

          if (account.type == 'bank') iconData = Icons.account_balance;
          if (account.type == 'card') iconData = Icons.credit_card;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1),
                child: Icon(iconData, color: Theme.of(context).primaryColor),
              ),
              title: Text(
                account.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(account.type.toUpperCase()),
              trailing: Text(
                '${account.balance.toStringAsFixed(2)} DH',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement Add Account functionality later
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
