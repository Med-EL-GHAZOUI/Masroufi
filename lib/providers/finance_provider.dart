import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../services/local_db_service.dart';

class FinanceProvider with ChangeNotifier {
  List<Account> _accounts = [];
  List<TransactionCategory> _categories = [];
  List<TransactionModel> _transactions = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _goals = [];

  List<Account> get accounts => _accounts;
  List<TransactionCategory> get categories => _categories;
  List<TransactionModel> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<SavingsGoal> get goals => _goals;

  final dbService = LocalDbService.instance;

  Future<void> loadData() async {
    await _loadAccounts();
    await _loadCategories();
    await _loadTransactions();
    await _loadBudgets();
    await _loadGoals();
    notifyListeners();
  }

  // --- Accounts ---
  Future<void> _loadAccounts() async {
    final isar = await dbService.isar;
    _accounts = await isar.accounts.where().findAll();
  }

  Future<void> addAccount(Account account) async {
    final isar = await dbService.isar;
    await isar.writeTxn(() async {
      await isar.accounts.put(account);
    });
    await _loadAccounts();
    notifyListeners();
  }

  Future<void> updateAccountBalance(int accountId, double amountChange) async {
    final isar = await dbService.isar;
    final account = _accounts.firstWhere((a) => a.id == accountId);
    final updatedAccount = account.copyWith(
      balance: account.balance + amountChange,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    await isar.writeTxn(() async {
      await isar.accounts.put(updatedAccount);
    });
    await _loadAccounts();
    notifyListeners();
  }

  // --- Categories ---
  Future<void> _loadCategories() async {
    final isar = await dbService.isar;
    _categories = await isar.transactionCategorys.where().findAll();
  }

  // --- Transactions ---
  Future<void> _loadTransactions() async {
    final isar = await dbService.isar;
    _transactions = await isar.transactionModels
        .where()
        .sortByDateDesc()
        .findAll();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final isar = await dbService.isar;
    await isar.writeTxn(() async {
      await isar.transactionModels.put(transaction);
    });

    // Update account balance
    double amountChange = transaction.isExpense
        ? -transaction.amount
        : transaction.amount;
    await updateAccountBalance(transaction.accountId, amountChange);

    await _loadTransactions();
    notifyListeners();
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    final isar = await dbService.isar;
    await isar.writeTxn(() async {
      await isar.transactionModels.delete(transaction.id);
      // Wait, we also need to delete from Firestore if we do full sync, but offline-first deletes
      // usually require soft deletes. For now, we will ignore soft deletes and just delete locally.
    });

    // Revert account balance
    double amountChange = transaction.isExpense
        ? transaction.amount
        : -transaction.amount;
    await updateAccountBalance(transaction.accountId, amountChange);

    await _loadTransactions();
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel oldTxn, TransactionModel newTxn) async {
    final isar = await dbService.isar;
    await isar.writeTxn(() async {
      await isar.transactionModels.put(newTxn);
    });

    // Revert old transaction effect
    double oldAmountChange = oldTxn.isExpense ? oldTxn.amount : -oldTxn.amount;
    await updateAccountBalance(oldTxn.accountId, oldAmountChange);

    // Apply new transaction effect
    double newAmountChange = newTxn.isExpense ? -newTxn.amount : newTxn.amount;
    await updateAccountBalance(newTxn.accountId, newAmountChange);

    await _loadTransactions();
    notifyListeners();
  }

  Future<void> archiveTransaction(int id, bool archive) async {
    final isar = await dbService.isar;
    final txn = await isar.transactionModels.get(id);
    if (txn != null) {
      txn.isArchived = archive;
      await isar.writeTxn(() async {
        await isar.transactionModels.put(txn);
      });
      await _loadTransactions();
      notifyListeners();
    }
  }

  // --- Budgets ---
  Future<void> _loadBudgets() async {
    final isar = await dbService.isar;
    _budgets = await isar.budgets.where().findAll();
  }

  Future<void> addBudget(Budget budget) async {
    final isar = await dbService.isar;
    await isar.writeTxn(() async {
      await isar.budgets.put(budget);
    });
    await _loadBudgets();
    notifyListeners();
  }

  // --- Goals ---
  Future<void> _loadGoals() async {
    final isar = await dbService.isar;
    _goals = await isar.savingsGoals.where().findAll();
  }

  Future<void> addGoal(SavingsGoal goal) async {
    final isar = await dbService.isar;
    await isar.writeTxn(() async {
      await isar.savingsGoals.put(goal);
    });
    await _loadGoals();
    notifyListeners();
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    final isar = await dbService.isar;
    await isar.writeTxn(() async {
      goal.updatedAt = DateTime.now();
      await isar.savingsGoals.put(goal);
    });
    await _loadGoals();
    notifyListeners();
  }

  Future<void> deleteGoal(int id) async {
    final isar = await dbService.isar;
    await isar.writeTxn(() async {
      await isar.savingsGoals.delete(id);
    });
    await _loadGoals();
    notifyListeners();
  }

  // --- Calculations ---
  double get totalBalance =>
      _accounts.fold(0, (sum, item) => sum + item.balance);

  double get totalIncome {
    return _transactions
        .where((t) => !t.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
  }
}
