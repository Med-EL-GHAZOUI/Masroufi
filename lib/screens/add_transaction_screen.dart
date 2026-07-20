import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';
import '../widgets/premium_header.dart';

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
          SnackBar(
            content: Text('select_category_account_error'.tr()),
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
        provider.updateTransaction(widget.transactionToEdit!, transaction);
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
      body: Column(
        children: [
          PremiumHeader(
            title: widget.transactionToEdit != null
                ? 'edit_transaction'.tr()
                : 'add_transaction'.tr(),
            leading: const BackButton(color: Colors.white),
          ),
          Expanded(
            child: SingleChildScrollView(
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
                          label: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('expense'.tr()),
                          ),
                          selected: _isExpense,
                          selectedColor: Colors.red.withOpacity(0.2),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: _isExpense ? Colors.red[800] : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (val) {
                            setState(() {
                              _isExpense = true;
                              _selectedCategoryId = null; // Reset category selection
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('income'.tr()),
                          ),
                          selected: !_isExpense,
                          selectedColor: Colors.green.withOpacity(0.2),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: !_isExpense ? Colors.green[800] : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (val) {
                            setState(() {
                              _isExpense = false;
                              _selectedCategoryId = null; // Reset category selection
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'amount_dh'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'required_field'.tr();
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'invalid_amount'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'note_description'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'category'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat.id,
                          child: Text(cat.name.tr()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                      },
                      validator: (value) => value == null ? 'required_field'.tr() : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedAccountId,
                      decoration: InputDecoration(
                        labelText: 'account'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                      ),
                      items: accounts.map((acc) {
                        return DropdownMenuItem<int>(
                          value: acc.id,
                          child: Text(acc.name.tr()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedAccountId = val;
                        });
                      },
                      validator: (value) => value == null ? 'required_field'.tr() : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                      ),
                      child: Text(
                        'save'.tr(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
