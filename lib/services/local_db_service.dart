import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/person.dart';
import '../models/credit_transaction.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._init();
  Isar? _isar;

  LocalDbService._init();

  Future<Isar> get isar async {
    if (_isar != null) return _isar!;
    _isar = await _initDB();
    return _isar!;
  }

  Future<Isar> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open([
      AccountSchema,
      TransactionCategorySchema,
      TransactionModelSchema,
      BudgetSchema,
      SavingsGoalSchema,
      PersonSchema,
      CreditTransactionSchema,
    ], directory: dir.path);

    // Seed default data if accounts are empty
    final accountCount = await isar.accounts.count();
    if (accountCount == 0) {
      await _seedDatabase(isar);
    }

    return isar;
  }

  Future<void> _seedDatabase(Isar isar) async {
    await isar.writeTxn(() async {
      // Insert default accounts
      await isar.accounts.putAll([
        Account(name: 'Espèces', balance: 0.0, type: 'cash'),
        Account(name: 'Banque', balance: 0.0, type: 'bank'),
        Account(name: 'Carte bancaire', balance: 0.0, type: 'card'),
      ]);

      // Insert default categories
      await isar.transactionCategorys.putAll([
        TransactionCategory(
          name: 'Alimentation',
          icon: 'restaurant',
          color: '#FF5722',
          isExpense: true,
        ),
        TransactionCategory(
          name: 'Transport',
          icon: 'directions_car',
          color: '#2196F3',
          isExpense: true,
        ),
        TransactionCategory(
          name: 'Shopping',
          icon: 'shopping_bag',
          color: '#E91E63',
          isExpense: true,
        ),
        TransactionCategory(
          name: 'Santé',
          icon: 'local_hospital',
          color: '#F44336',
          isExpense: true,
        ),
        TransactionCategory(
          name: 'Éducation',
          icon: 'school',
          color: '#9C27B0',
          isExpense: true,
        ),
        TransactionCategory(
          name: 'Loisirs',
          icon: 'sports_esports',
          color: '#FF9800',
          isExpense: true,
        ),
        TransactionCategory(
          name: 'Factures',
          icon: 'receipt',
          color: '#607D8B',
          isExpense: true,
        ),
        TransactionCategory(
          name: 'Voyage',
          icon: 'flight',
          color: '#00BCD4',
          isExpense: true,
        ),
        TransactionCategory(
          name: 'Salaire',
          icon: 'attach_money',
          color: '#4CAF50',
          isExpense: false,
        ),
        TransactionCategory(
          name: 'Business',
          icon: 'business_center',
          color: '#8BC34A',
          isExpense: false,
        ),
        TransactionCategory(
          name: 'Cadeaux',
          icon: 'card_giftcard',
          color: '#CDDC39',
          isExpense: false,
        ),
      ]);
    });
  }

  Future<void> close() async {
    final db = await instance.isar;
    await db.close();
  }
}
