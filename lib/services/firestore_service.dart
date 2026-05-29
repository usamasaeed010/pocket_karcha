import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/user_profile_model.dart';
import 'package:pocket_karcha/services/firebase_service.dart';

class FirestoreService {
  FirestoreService(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _expenses(String uid) =>
      _user(uid).collection('expenses');

  Future<void> createUserProfile(UserProfileModel profile) async {
    await _user(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> saveUserProfile(UserProfileModel profile) async {
    await _user(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<UserProfileModel?> getUserProfile(String uid) async {
    final snap = await _user(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfileModel.fromMap(uid, snap.data()!);
  }

  Stream<List<ExpenseModel>> watchExpenses(String uid) {
    return _expenses(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ExpenseModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> addExpense(String uid, ExpenseModel expense) async {
    await _expenses(uid).doc(expense.id).set(expense.toMap());
  }

  Future<void> updateExpenseReceipt(
    String uid,
    String expenseId,
    String receiptUrl,
  ) async {
    await _expenses(uid).doc(expenseId).update({'receiptUrl': receiptUrl});
  }

  Future<void> updateAvatarUrl(String uid, String avatarUrl) async {
    await _user(uid).set({'avatarUrl': avatarUrl}, SetOptions(merge: true));
  }

  Future<void> deleteExpense(String uid, String expenseId) async {
    await _expenses(uid).doc(expenseId).delete();
  }

  static FirestoreService? create() {
    if (!FirebaseService.isReady) return null;
    return FirestoreService(FirebaseFirestore.instance);
  }
}
