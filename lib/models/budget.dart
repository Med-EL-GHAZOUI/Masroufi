import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'budget.g.dart';

@collection
class Budget {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String firestoreId = const Uuid().v4();
  double amount;
  int? categoryId;
  String month;
  DateTime updatedAt = DateTime.now();
  bool isSynced = false;

  Budget({
    this.id = Isar.autoIncrement,
    required this.amount,
    this.categoryId,
    required this.month,
  });

  Map<String, dynamic> toMap() {
    return {
      'firestoreId': firestoreId,
      'amount': amount,
      'categoryId': categoryId,
      'month': month,
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
        amount: map['amount'],
        categoryId: map['categoryId'],
        month: map['month'],
      )
      ..firestoreId = map['firestoreId'] ?? const Uuid().v4()
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now()
      ..isSynced = map['isSynced'] ?? false;
  }
}
