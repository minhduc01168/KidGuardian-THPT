import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:kidguardian/core/error/app_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
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
    return _firebaseAuth.authStateChanges().switchMap((firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(null);
      } else {
        // Lắng nghe thay đổi từ Firestore thay vì get() 1 lần.
        // Dùng where((doc) => doc.exists) để block stream cho đến khi document thực sự được tạo.
        // Dùng switchMap để hủy snapshot stream cũ khi đăng xuất (firebaseUser = null).
        return _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .snapshots()
            .where((doc) => doc.exists)
            .map((doc) => UserModel.fromFirestore(doc))
            .handleError((e) {
              print('Error in authStateChanges stream: $e');
            });
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
        throw AppException('Đăng nhập thất bại: Lỗi hệ thống từ Firebase.');
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
      if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
        throw AppException('Không có kết nối mạng. Vui lòng kiểm tra lại Wifi/4G.');
      }
      throw AppException('Đã có lỗi xảy ra. Vui lòng thử lại sau.');
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
        throw AppException('Đăng ký thất bại: Lỗi hệ thống từ Firebase.');
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
      print('FirebaseAuthException during registration: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during registration: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
        throw AppException('Không có kết nối mạng. Vui lòng kiểm tra lại Wifi/4G.');
      }
      throw AppException('Đã có lỗi xảy ra. Vui lòng thử lại sau.');
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
  Future<void> updateProfile(String uid, {String? displayName, String? familyId}) async {
    final updates = <String, dynamic>{};
    if (displayName != null) {
      updates['displayName'] = displayName;
      await _firebaseAuth.currentUser?.updateDisplayName(displayName);
    }
    if (familyId != null) {
      updates['familyId'] = familyId;
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
      throw AppException('Không thể kết nối đến máy chủ dữ liệu.');
    }
  }
  
  AppException _handleAuthException(firebase.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return AppException('Thông tin đăng nhập không chính xác');
      case 'wrong-password':
        return AppException('Sai mật khẩu');
      case 'email-already-in-use':
        return AppException('Email này đã được đăng ký');
      case 'weak-password':
        return AppException('Mật khẩu quá yếu (cần tối thiểu 6 ký tự)');
      case 'invalid-email':
        return AppException('Định dạng Email không hợp lệ');
      case 'network-request-failed':
        return AppException('Không có kết nối mạng. Vui lòng kiểm tra lại Wifi/4G.');
      default:
        return AppException('Lỗi xác thực. Vui lòng thử lại sau.');
    }
  }
}
