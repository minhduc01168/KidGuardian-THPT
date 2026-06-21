import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:kidguardian/data/repositories/auth_repository_impl.dart';
import 'package:kidguardian/domain/entities/user.dart';

void main() {
  group('AuthRepositoryImpl with Fake Firebase Integration', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late AuthRepositoryImpl authRepository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      
      // Khởi tạo Auth Mock với một User rỗng (chưa đăng nhập)
      mockAuth = MockFirebaseAuth();
      
      authRepository = AuthRepositoryImpl(
        firebaseAuth: mockAuth,
        firestore: fakeFirestore,
      );
    });

    test('Đăng ký tạo tài khoản trên Firebase Auth và lưu dữ liệu đúng chuẩn vào Firestore', () async {
      final user = await authRepository.register(
        'test@kidguardian.com',
        'password123',
        'Test Parent',
        UserRole.parent,
      );

      // 1. Kiểm tra đối tượng trả về
      expect(user.email, equals('test@kidguardian.com'));
      expect(user.role, equals(UserRole.parent));

      // 2. Kiểm tra Firestore data xem Document có được tạo đúng thư mục 'users' không
      final docSnapshot = await fakeFirestore.collection('users').doc(user.uid).get();
      expect(docSnapshot.exists, isTrue);
      
      final data = docSnapshot.data()!;
      expect(data['email'], equals('test@kidguardian.com'));
      expect(data['role'], equals('parent'));
      expect(data['displayName'], equals('Test Parent'));
      expect(data['createdAt'], isNotNull);
    });

    test('Đăng nhập thành công sẽ query trực tiếp vào Firestore để lấy đúng Role và FamilyId', () async {
      // Giả lập Database đã có dữ liệu từ trước
      await fakeFirestore.collection('users').doc('mock_uid_123').set({
        'uid': 'mock_uid_123',
        'email': 'child@kidguardian.com',
        'displayName': 'Test Child',
        'role': 'child',
        'familyId': 'family_456',
        'createdAt': DateTime.now(),
      });

      // Giả lập tài khoản đã tồn tại trong Firebase Auth
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'mock_uid_123',
        email: 'child@kidguardian.com',
        displayName: 'Test Child',
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser);
      authRepository = AuthRepositoryImpl(firebaseAuth: mockAuth, firestore: fakeFirestore);

      final user = await authRepository.login('child@kidguardian.com', 'password123');

      // Kiểm tra dữ liệu Map từ Firestore sang Dart Object
      expect(user.uid, equals('mock_uid_123'));
      expect(user.role, equals(UserRole.child)); // Phải là child như db
      expect(user.familyId, equals('family_456'));
    });
  });
}
