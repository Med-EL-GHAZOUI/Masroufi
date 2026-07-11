import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'goal.g.dart';

@collection
class SavingsGoal {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String firestoreId = const Uuid().v4();
  String title;
  double targetAmount;
  double currentAmount;
  DateTime deadline;
  String? icon;
  String? color;
  DateTime updatedAt = DateTime.now();
  bool isSynced = false;

  SavingsGoal({
    this.id = Isar.autoIncrement,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadline,
    this.icon,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'firestoreId': firestoreId,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'icon': icon,
      'color': color,
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
        title: map['title'],
        targetAmount: map['targetAmount'],
        currentAmount: map['currentAmount'] ?? 0.0,
        deadline: DateTime.parse(map['deadline']),
        icon: map['icon'],
        color: map['color'],
      )
      ..firestoreId = map['firestoreId'] ?? const Uuid().v4()
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now()
      ..isSynced = map['isSynced'] ?? false;
  }

  SavingsGoal copyWith({
    Id? id,
    String? firestoreId,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? icon,
    String? color,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return SavingsGoal(
        id: id ?? this.id,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        deadline: deadline ?? this.deadline,
        icon: icon ?? this.icon,
        color: color ?? this.color,
      )
      ..firestoreId = firestoreId ?? this.firestoreId
      ..updatedAt = updatedAt ?? this.updatedAt
      ..isSynced = isSynced ?? this.isSynced;
  }
}
