import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  
  AuthRepositoryImpl({
    firebase.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _getUserFromFirestore(firebaseUser.uid);
    });
  }
  
  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return await _getUserFromFirestore(firebaseUser.uid);
  }
  
  @override
  Future<User> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Login failed');
      }
      
      final user = await _getUserFromFirestore(credential.user!.uid);
      if (user == null) {
        throw Exception('User data not found');
      }
      
      return user;
    } on firebase.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  @override
  Future<User> register(String email, String password, String name, UserRole role) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Registration failed');
      }
      
      // Update display name
      await credential.user!.updateDisplayName(name);
      
      // Create user document in Firestore
      final userModel = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: name,
        role: role,
        createdAt: DateTime.now(),
      );
      
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toMap());
      
      return userModel;
    } on firebase.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  @override
  Future<User> createChildAccount(String name, int age, String familyId) async {
    try {
      // Generate a more secure random password
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (timestamp * 2654435761) & 0xFFFFFFFF; // Knuth hash
      final childEmail = '${name.toLowerCase().replaceAll(' ', '')}_$timestamp@kidguardian.local';
      final childPassword = 'KG_${random.toRadixString(16).padLeft(8, '0')}_$timestamp';

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: childEmail,
        password: childPassword,
      );

      if (credential.user == null) {
        throw Exception('Tạo tài khoản thất bại');
      }

      await credential.user!.updateDisplayName(name);

      final userModel = UserModel(
        uid: credential.user!.uid,
        email: childEmail,
        displayName: name,
        role: UserRole.child,
        familyId: familyId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toMap());

      return userModel;
    } on firebase.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> linkChildToFamily(String childUid, String familyId) async {
    await _firestore.collection('users').doc(childUid).update({
      'familyId': familyId,
      'linkedTo': familyId,
    });
  }

  @override
  Future<void> logout() async {
    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> updateProfile(String uid, {String? displayName}) async {
    final updates = <String, dynamic>{};
    if (displayName != null) {
      updates['displayName'] = displayName;
      await _firebaseAuth.currentUser?.updateDisplayName(displayName);
    }
    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }
  
  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  Future<User?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }
  
  Exception _handleAuthException(firebase.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Không tìm thấy tài khoản');
      case 'wrong-password':
        return Exception('Sai mật khẩu');
      case 'email-already-in-use':
        return Exception('Email đã được sử dụng');
      case 'weak-password':
        return Exception('Mật khẩu quá yếu');
      case 'invalid-email':
        return Exception('Email không hợp lệ');
      default:
        return Exception('Lỗi xác thực: ${e.message}');
    }
  }
}
