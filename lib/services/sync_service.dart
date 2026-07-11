import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import '../services/local_db_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/goal.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;

  void startSyncListener() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        syncData();
      }
    });
  }

  void stopSyncListener() {
    _connectivitySub?.cancel();
  }

  Future<void> syncData() async {
    if (_isSyncing) return;

    final user = _auth.currentUser;
    if (user == null) return; // Not logged in, can't sync

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return; // Offline

    _isSyncing = true;
    try {
      await _pushUnsyncedData(user.uid);
      await _pullUpdatedData(user.uid);
    } catch (e) {
      debugPrint("Erreur lors de la synchronisation: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushUnsyncedData(String uid) async {
    final isar = await LocalDbService.instance.isar;
    final batch = _firestore.batch();
    int batchCount = 0;

    Future<void> commitBatchIfFull() async {
      if (batchCount >= 450) {
        await batch.commit();
        batchCount = 0;
      }
    }

    // Transactions
    final unsyncedTransactions = await isar.transactionModels
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    for (var t in unsyncedTransactions) {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(t.firestoreId);
      batch.set(docRef, t.toMap());
      batchCount++;
      await commitBatchIfFull();
    }

    // Accounts
    final unsyncedAccounts = await isar.accounts
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    for (var a in unsyncedAccounts) {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .doc(a.firestoreId);
      batch.set(docRef, a.toMap());
      batchCount++;
      await commitBatchIfFull();
    }

    // Categories
    final unsyncedCategories = await isar.transactionCategorys
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    for (var c in unsyncedCategories) {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(c.firestoreId);
      batch.set(docRef, c.toMap());
      batchCount++;
      await commitBatchIfFull();
    }

    // Budgets
    final unsyncedBudgets = await isar.budgets
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    for (var b in unsyncedBudgets) {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(b.firestoreId);
      batch.set(docRef, b.toMap());
      batchCount++;
      await commitBatchIfFull();
    }

    // Goals
    final unsyncedGoals = await isar.savingsGoals
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    for (var g in unsyncedGoals) {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('goals')
          .doc(g.firestoreId);
      batch.set(docRef, g.toMap());
      batchCount++;
      await commitBatchIfFull();
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    // Mark as synced locally
    await isar.writeTxn(() async {
      for (var t in unsyncedTransactions) {
        t.isSynced = true;
        await isar.transactionModels.put(t);
      }
      for (var a in unsyncedAccounts) {
        a.isSynced = true;
        await isar.accounts.put(a);
      }
      for (var c in unsyncedCategories) {
        c.isSynced = true;
        await isar.transactionCategorys.put(c);
      }
      for (var b in unsyncedBudgets) {
        b.isSynced = true;
        await isar.budgets.put(b);
      }
      for (var g in unsyncedGoals) {
        g.isSynced = true;
        await isar.savingsGoals.put(g);
      }
    });
  }

  Future<void> _pullUpdatedData(String uid) async {
    final isar = await LocalDbService.instance.isar;

    // We fetch everything for simplicity. For production, we should store a `lastSyncTime` locally
    // and only fetch documents where `updatedAt > lastSyncTime`.

    // Transactions
    final transSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .get();
    await isar.writeTxn(() async {
      for (var doc in transSnap.docs) {
        final t = TransactionModel.fromMap(doc.data());
        t.isSynced = true;
        // Upsert by firestoreId
        final existing = await isar.transactionModels
            .filter()
            .firestoreIdEqualTo(t.firestoreId)
            .findFirst();
        if (existing != null) {
          t.id = existing.id; // Keep local int id
          // Simple conflict resolution: server wins if updated later
          if (t.updatedAt.isAfter(existing.updatedAt)) {
            await isar.transactionModels.put(t);
          }
        } else {
          await isar.transactionModels.put(t);
        }
      }
    });

    // Accounts
    final accSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .get();
    await isar.writeTxn(() async {
      for (var doc in accSnap.docs) {
        final a = Account.fromMap(doc.data());
        a.isSynced = true;
        final existing = await isar.accounts
            .filter()
            .firestoreIdEqualTo(a.firestoreId)
            .findFirst();
        if (existing != null) {
          if (a.updatedAt.isAfter(existing.updatedAt)) {
            await isar.accounts.put(a.copyWith(id: existing.id));
          }
        } else {
          await isar.accounts.put(a);
        }
      }
    });

    // Categories
    final catSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('categories')
        .get();
    await isar.writeTxn(() async {
      for (var doc in catSnap.docs) {
        final c = TransactionCategory.fromMap(doc.data());
        c.isSynced = true;
        final existing = await isar.transactionCategorys
            .filter()
            .firestoreIdEqualTo(c.firestoreId)
            .findFirst();
        if (existing != null) {
          c.id = existing.id;
          if (c.updatedAt.isAfter(existing.updatedAt)) {
            await isar.transactionCategorys.put(c);
          }
        } else {
          await isar.transactionCategorys.put(c);
        }
      }
    });

    // Budgets
    final budSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .get();
    await isar.writeTxn(() async {
      for (var doc in budSnap.docs) {
        final b = Budget.fromMap(doc.data());
        b.isSynced = true;
        final existing = await isar.budgets
            .filter()
            .firestoreIdEqualTo(b.firestoreId)
            .findFirst();
        if (existing != null) {
          b.id = existing.id;
          if (b.updatedAt.isAfter(existing.updatedAt)) {
            await isar.budgets.put(b);
          }
        } else {
          await isar.budgets.put(b);
        }
      }
    });

    // Goals
    final goalSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('goals')
        .get();
    await isar.writeTxn(() async {
      for (var doc in goalSnap.docs) {
        final g = SavingsGoal.fromMap(doc.data());
        g.isSynced = true;
        final existing = await isar.savingsGoals
            .filter()
            .firestoreIdEqualTo(g.firestoreId)
            .findFirst();
        if (existing != null) {
          final merged = g.copyWith(id: existing.id);
          if (g.updatedAt.isAfter(existing.updatedAt)) {
            await isar.savingsGoals.put(merged);
          }
        } else {
          await isar.savingsGoals.put(g);
        }
      }
    });
  }
}
