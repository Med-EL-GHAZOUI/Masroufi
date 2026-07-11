import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/person.dart';
import '../models/credit_transaction.dart';
import '../services/local_db_service.dart';

class CreditProvider with ChangeNotifier {
  List<Person> _persons = [];
  List<CreditTransaction> _transactions = [];

  List<Person> get persons => _persons;
  List<CreditTransaction> get transactions => _transactions;

  final dbService = LocalDbService.instance;

  Future<void> loadData() async {
    final isar = await dbService.isar;
    _persons = await isar.persons.where().findAll();
    _transactions = await isar.creditTransactions.where().findAll();
    notifyListeners();
  }

  Future<void> addPerson(Person person) async {
    final isar = await dbService.isar;
    await isar.writeTxn(() async {
      await isar.persons.put(person);
    });
    await loadData();
  }

  Future<void> addTransaction(CreditTransaction transaction) async {
    final isar = await dbService.isar;
    await isar.writeTxn(() async {
      await isar.creditTransactions.put(transaction);
      await transaction.person.save();
    });
    await loadData();
  }

  Future<void> updateTransaction(CreditTransaction transaction) async {
    final isar = await dbService.isar;
    await isar.writeTxn(() async {
      await isar.creditTransactions.put(transaction);
      await transaction.person.save();
    });
    await loadData();
  }

  Future<void> deleteTransaction(int id) async {
    final isar = await dbService.isar;
    await isar.writeTxn(() async {
      await isar.creditTransactions.delete(id);
    });
    await loadData();
  }

  double getTotalGiven(bool isClient) {
    // لي عطيت
    double total = 0;
    for (var p in _persons.where((p) => p.isClient == isClient)) {
      final txns = _transactions.where(
        (t) => t.person.value?.id == p.id && !t.isReceived,
      );
      for (var t in txns) {
        total += t.amount;
      }
    }
    return total;
  }

  double getTotalReceived(bool isClient) {
    // لي خديت
    double total = 0;
    for (var p in _persons.where((p) => p.isClient == isClient)) {
      final txns = _transactions.where(
        (t) => t.person.value?.id == p.id && t.isReceived,
      );
      for (var t in txns) {
        total += t.amount;
      }
    }
    return total;
  }

  double getPersonBalance(int personId) {
    // Return net balance for a person
    // If received > given, balance is positive, etc.
    double received = 0;
    double given = 0;
    final txns = _transactions.where((t) => t.person.value?.id == personId);
    for (var t in txns) {
      if (t.isReceived) {
        received += t.amount;
      } else {
        given += t.amount;
      }
    }
    return received - given; // Positive means we took more than we gave
  }
}
