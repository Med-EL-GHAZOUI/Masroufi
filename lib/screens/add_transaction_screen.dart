import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isExpense = true;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      _isExpense = widget.transactionToEdit!.isExpense;
      _amountController.text = widget.transactionToEdit!.amount.toString();
      _noteController.text = widget.transactionToEdit!.note;
      _selectedDate = widget.transactionToEdit!.date;
      _selectedCategoryId = widget.transactionToEdit!.categoryId;
      _selectedAccountId = widget.transactionToEdit!.accountId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null || _selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une catégorie et un compte'),
          ),
        );
        return;
      }

      final amount = double.parse(_amountController.text);
      final transaction = TransactionModel(
        id: widget.transactionToEdit?.id ?? Isar.autoIncrement,
        amount: amount,
        date: _selectedDate,
        note: _noteController.text,
        categoryId: _selectedCategoryId!,
        accountId: _selectedAccountId!,
        isExpense: _isExpense,
      );

      final provider = Provider.of<FinanceProvider>(context, listen: false);

      if (widget.transactionToEdit != null) {
        // Implement update later
        // provider.updateTransaction(transaction);
      } else {
        provider.addTransaction(transaction);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final categories = provider.categories
        .where((c) => c.isExpense == _isExpense)
        .toList();
    final accounts = provider.accounts;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transactionToEdit != null
              ? 'Modifier'
              : 'Ajouter une Transaction',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Dépense'),
                    selected: _isExpense,
                    selectedColor: Colors.red.withOpacity(0.2),
                    onSelected: (val) {
                      setState(() {
                        _isExpense = true;
                        _selectedCategoryId = null; // Reset category selection
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('Revenu'),
                    selected: !_isExpense,
                    selectedColor: Colors.green.withOpacity(0.2),
                    onSelected: (val) {
                      setState(() {
                        _isExpense = false;
                        _selectedCategoryId = null; // Reset category selection
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant (DH)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Veuillez entrer un montant valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note / Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                  });
                },
                validator: (value) => value == null ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'Compte',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                items: accounts.map((acc) {
                  return DropdownMenuItem<int>(
                    value: acc.id,
                    child: Text(acc.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedAccountId = val;
                  });
                },
                validator: (value) => value == null ? 'Requis' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
