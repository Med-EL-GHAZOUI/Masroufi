import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'account.g.dart';

@collection
class Account {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String firestoreId = const Uuid().v4();
  String name;
  double balance;
  String type; // 'cash', 'bank', 'card'
  DateTime updatedAt = DateTime.now();
  bool isSynced = false;

  Account({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.balance,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'firestoreId': firestoreId,
      'name': name,
      'balance': balance,
      'type': type,
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
        name: map['name'],
        balance: map['balance'],
        type: map['type'],
      )
      ..firestoreId = map['firestoreId'] ?? const Uuid().v4()
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now()
      ..isSynced = map['isSynced'] ?? false;
  }

  Account copyWith({
    Id? id,
    String? firestoreId,
    String? name,
    double? balance,
    String? type,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Account(
        id: id ?? this.id,
        name: name ?? this.name,
        balance: balance ?? this.balance,
        type: type ?? this.type,
      )
      ..firestoreId = firestoreId ?? this.firestoreId
      ..updatedAt = updatedAt ?? this.updatedAt
      ..isSynced = isSynced ?? this.isSynced;
  }
}
