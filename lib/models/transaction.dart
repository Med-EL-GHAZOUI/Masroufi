import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'transaction.g.dart';

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String firestoreId = const Uuid().v4();
  double amount;
  DateTime date;
  String note;
  int categoryId;
  int accountId;
  bool isExpense;
  String? receiptPath;
  DateTime updatedAt = DateTime.now();
  bool isSynced = false;
  bool isArchived = false;

  TransactionModel({
    this.id = Isar.autoIncrement,
    required this.amount,
    required this.date,
    required this.note,
    required this.categoryId,
    required this.accountId,
    required this.isExpense,
    this.receiptPath,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'firestoreId': firestoreId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'categoryId': categoryId,
      'accountId': accountId,
      'isExpense': isExpense ? 1 : 0,
      'receiptPath': receiptPath,
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
        amount: map['amount'],
        date: DateTime.parse(map['date']),
        note: map['note'],
        categoryId: map['categoryId'],
        accountId: map['accountId'],
        isExpense: map['isExpense'] == 1 || map['isExpense'] == true,
        receiptPath: map['receiptPath'],
      )
      ..firestoreId = map['firestoreId'] ?? const Uuid().v4()
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now()
      ..isSynced = map['isSynced'] ?? false;
  }
}
