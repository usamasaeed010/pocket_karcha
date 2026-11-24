import 'dart:async';
// import 'dart:io'; // Image attachments are disabled for now.

import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/services/firestore_service.dart';
// import 'package:pocket_karcha/services/storage_service.dart';

class ExpenseRepository {
  ExpenseRepository({
    FirestoreService? firestore,
    // Image attachments are disabled for now — receipts are not uploaded.
    // StorageService? storage,
  }) : _firestore = firestore;
  // _storage = storage;

  final FirestoreService? _firestore;
  // final StorageService? _storage;
  final List<ExpenseModel> _local = [];
  final _controller = StreamController<List<ExpenseModel>>.broadcast();

  Stream<List<ExpenseModel>> watch(String? uid) {
    if (_firestore != null && uid != null) {
      return _firestore.watchExpenses(uid);
    }
    _emitLocal();
    return _controller.stream;
  }

  Future<ExpenseModel> add(String? uid, ExpenseModel expense) async {
    if (_firestore != null && uid != null) {
      await _firestore.addExpense(uid, expense);

      // Image attachments are disabled for now.
      // if (receiptFile != null && _storage != null) {
      //   final url = await _storage.uploadReceipt(
      //     uid: uid,
      //     expenseId: expense.id,
      //     file: receiptFile,
      //   );
      //   saved = saved.copyWith(receiptUrl: url);
      //   await _firestore.updateExpenseReceipt(uid, expense.id, url);
      // }
      return expense;
    }

    // Image attachments are disabled for now.
    // if (receiptFile != null) {
    //   local = local.copyWith(receiptUrl: receiptFile.path);
    // }
    _local.insert(0, expense);
    _emitLocal();
    return expense;
  }

  Future<ExpenseModel> update(String? uid, ExpenseModel expense) async {
    if (_firestore != null && uid != null) {
      await _firestore.updateExpense(uid, expense);

      // Image attachments are disabled for now.
      // if (receiptFile != null && _storage != null) {
      //   final url = await _storage.uploadReceipt(
      //     uid: uid,
      //     expenseId: expense.id,
      //     file: receiptFile,
      //   );
      //   saved = saved.copyWith(receiptUrl: url);
      //   await _firestore.updateExpenseReceipt(uid, expense.id, url);
      // }
      return expense;
    }

    final index = _local.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      _local[index] = expense;
    }
    _emitLocal();
    return expense;
  }

  Future<void> delete(String? uid, String id) async {
    if (_firestore != null && uid != null) {
      await _firestore.deleteExpense(uid, id);
      return;
    }
    _local.removeWhere((e) => e.id == id);
    _emitLocal();
  }

  void _emitLocal() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_local));
    }
  }

  void dispose() => _controller.close();
}
