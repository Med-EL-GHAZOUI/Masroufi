import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/finance_provider.dart';
import 'add_transaction_screen.dart';
import '../widgets/premium_header.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final allTransactions = provider.transactions;

    final filteredTransactions = allTransactions.where((t) {
      if (t.isArchived != _showArchived) return false;
      final query = _searchQuery.toLowerCase();
      final noteMatch = t.note.toLowerCase().contains(query);
      final categoryMatch = t.categoryId.toString().contains(query);
      return noteMatch || categoryMatch;
    }).toList();

    return Column(
      children: [
        PremiumHeader(
          title: 'all_transactions'.tr(),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.archive : Icons.archive_outlined),
            tooltip: 'Afficher les archives',
            onPressed: () {
              setState(() {
                _showArchived = !_showArchived;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'search_transactions'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
        ), // close PremiumHeader
        Expanded(
          child: filteredTransactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'no_transactions_found'.tr(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final t = filteredTransactions[index];
                final isExpense = t.isExpense;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.isArchived 
                            ? Colors.grey.withOpacity(0.1)
                            : (isExpense
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isExpense
                            ? Icons.shopping_bag_outlined
                            : Icons.account_balance_wallet_outlined,
                        color: t.isArchived
                            ? Colors.grey
                            : (isExpense ? Colors.red : Colors.green),
                      ),
                    ),
                    title: Text(
                      (t.note.isNotEmpty ? t.note : 'transaction'.tr()) + (t.isArchived ? ' (Archivé)' : ''),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${t.date.day}/${t.date.month}/${t.date.year}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isExpense ? '-' : '+'}${t.amount.toStringAsFixed(2)} DH',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: t.isArchived
                                ? Colors.grey
                                : (isExpense ? Colors.red : Colors.green),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddTransactionScreen(transactionToEdit: t),
                                ),
                              );
                            } else if (value == 'archive') {
                              await provider.archiveTransaction(t.id, !t.isArchived);
                            } else if (value == 'delete') {
                              // Confirm delete
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('confirm'.tr()),
                                  content: Text('delete_transaction_confirm'.tr()),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text('cancel'.tr()),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await provider.deleteTransaction(t);
                                        Navigator.pop(ctx);
                                      },
                                      child: Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, size: 20),
                                  const SizedBox(width: 8),
                                  Text('edit'.tr()),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'archive',
                              child: Row(
                                children: [
                                  Icon(t.isArchived ? Icons.unarchive : Icons.archive, size: 20),
                                  const SizedBox(width: 8),
                                  Text(t.isArchived ? 'Désarchiver' : 'Archiver'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ),
      ],
    );
  }
}
