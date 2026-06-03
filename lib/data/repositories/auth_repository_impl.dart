import 'package:firebase_core/firebase_core.dart';
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
      try {
        return await _getUserFromFirestore(firebaseUser.uid);
      } catch (e) {
        print('Error in authStateChanges stream: $e');
        return UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'User',
          role: UserRole.parent,
          createdAt: DateTime.now(),
        );
      }
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
        throw Exception('Đăng nhập thất bại: Không nhận được thông tin người dùng');
      }
      
      print('Firebase Auth successful for uid: ${credential.user!.uid}');
      
      final user = await _getUserFromFirestore(credential.user!.uid);
      if (user == null) {
        // User exists in Auth but not in Firestore - create the document
        print('User document not found in Firestore, creating...');
        final newUser = UserModel(
          uid: credential.user!.uid,
          email: credential.user!.email ?? email,
          displayName: credential.user!.displayName ?? 'User',
          role: UserRole.parent, // Default role
          createdAt: DateTime.now(),
        );
        
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(newUser.toMap());
        
        return newUser;
      }
      
      return user;
    } on firebase.FirebaseAuthException catch (e) {
      print('FirebaseAuthException during login: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during login: $e');
      throw Exception('Đăng nhập thất bại: $e');
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
        throw Exception('Đăng ký thất bại: Không tạo được tài khoản');
      }
      
      print('Firebase Auth user created: ${credential.user!.uid}');
      
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
      
      print('User document created in Firestore');
      
      return userModel;
    } on firebase.FirebaseAuthException catch (e) {
      print('FirebaseAuthException during register: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during register: $e');
      throw Exception('Đăng ký thất bại: $e');
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

      // Create a secondary app instance to avoid signing out the parent
      final secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp_$timestamp', // unique name
        options: Firebase.app().options,
      );

      try {
        final secondaryAuth = firebase.FirebaseAuth.instanceFor(app: secondaryApp);
        final credential = await secondaryAuth.createUserWithEmailAndPassword(
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
      } finally {
        await secondaryApp.delete();
      }
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
      if (!doc.exists) {
        print('User document does not exist for uid: $uid');
        return null;
      }
      return UserModel.fromFirestore(doc);
    } on firebase.FirebaseAuthException {
      rethrow;
    } catch (e) {
      print('Error getting user from Firestore: $e');
      throw Exception('Không thể đọc thông tin người dùng: $e');
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
