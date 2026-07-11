import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'category.g.dart';

@collection
class TransactionCategory {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String firestoreId = const Uuid().v4();
  String name;
  String icon;
  String color;
  bool isExpense;
  DateTime updatedAt = DateTime.now();
  bool isSynced = false;

  TransactionCategory({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
  });

  Map<String, dynamic> toMap() {
    return {
      'firestoreId': firestoreId,
      'name': name,
      'icon': icon,
      'color': color,
      'isExpense': isExpense ? 1 : 0,
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory TransactionCategory.fromMap(Map<String, dynamic> map) {
    return TransactionCategory(
        name: map['name'],
        icon: map['icon'],
        color: map['color'],
        isExpense: map['isExpense'] == 1 || map['isExpense'] == true,
      )
      ..firestoreId = map['firestoreId'] ?? const Uuid().v4()
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now()
      ..isSynced = map['isSynced'] ?? false;
  }
}
