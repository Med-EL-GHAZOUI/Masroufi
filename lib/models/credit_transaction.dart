import 'package:isar/isar.dart';
import 'person.dart';

part 'credit_transaction.g.dart';

@collection
class CreditTransaction {
  Id id = Isar.autoIncrement;

  final person = IsarLink<Person>();

  late double amount;

  // true if you received money (لي خديت), false if you gave money (لي عطيت)
  late bool isReceived;

  String note = '';

  String? photoPath;

  DateTime date = DateTime.now();
}
