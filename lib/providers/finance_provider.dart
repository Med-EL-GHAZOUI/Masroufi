import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';

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
    SyncService.instance.syncData();
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
    SyncService.instance.syncData();
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
    SyncService.instance.syncData();
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
    SyncService.instance.syncData();
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
    SyncService.instance.syncData();
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
