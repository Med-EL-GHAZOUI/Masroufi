import 'package:isar/isar.dart';

part 'person.g.dart';

@collection
class Person {
  Id id = Isar.autoIncrement;

  late String name;
  String? phone;
  String? address;
  String? email;
  String? note;

  // true for client (الكليان), false for supplier (الفورنيسور)
  late bool isClient;

  DateTime createdAt = DateTime.now();
}
