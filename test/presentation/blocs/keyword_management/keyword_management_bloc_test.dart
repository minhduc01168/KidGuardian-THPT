import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kidguardian/presentation/blocs/keyword_management/keyword_management_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late KeywordManagementBloc bloc;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    bloc = KeywordManagementBloc(firestore: fakeFirestore);
  });

  tearDown(() {
    bloc.close();
  });

  group('KeywordManagementBloc', () {
    test('initial state is KeywordManagementInitial', () {
      expect(bloc.state, isA<KeywordManagementInitial>());
    });

    test('LoadKeywords loads default keywords when no custom set', () async {
      bloc.add(const LoadKeywords('family1'));
      await Future.delayed(const Duration(milliseconds: 500));

      expect(bloc.state, isA<KeywordManagementLoaded>());
      final state = bloc.state as KeywordManagementLoaded;
      expect(state.keywords, contains('tự tử'));
      expect(state.keywords, contains('đánh nhau'));
      expect(state.keywords, contains('cờ bạc'));
      expect(state.keywords, contains('ma túy'));
    });

    test('AddKeyword adds new keyword to list', () async {
      bloc.add(const LoadKeywords('family1'));
      await Future.delayed(const Duration(milliseconds: 500));

      bloc.add(const AddKeyword(familyId: 'family1', keyword: 'bắt nạt'));
      await Future.delayed(const Duration(milliseconds: 300));

      final state = bloc.state as KeywordManagementLoaded;
      expect(state.keywords, contains('bắt nạt'));
      expect(state.keywords.length, 5);
    });

    test('AddKeyword does not add duplicate keyword', () async {
      bloc.add(const LoadKeywords('family1'));
      await Future.delayed(const Duration(milliseconds: 500));

      bloc.add(const AddKeyword(familyId: 'family1', keyword: 'tự tử'));
      await Future.delayed(const Duration(milliseconds: 300));

      final state = bloc.state as KeywordManagementLoaded;
      expect(state.keywords.where((k) => k == 'tự tử').length, 1);
    });

    test('AddKeyword does not add empty string', () async {
      bloc.add(const LoadKeywords('family1'));
      await Future.delayed(const Duration(milliseconds: 500));

      bloc.add(const AddKeyword(familyId: 'family1', keyword: '  '));
      await Future.delayed(const Duration(milliseconds: 300));

      final state = bloc.state as KeywordManagementLoaded;
      expect(state.keywords.length, 4);
    });

    test('RemoveKeyword removes keyword from list', () async {
      bloc.add(const LoadKeywords('family1'));
      await Future.delayed(const Duration(milliseconds: 500));

      bloc.add(const RemoveKeyword(familyId: 'family1', keyword: 'ma túy'));
      await Future.delayed(const Duration(milliseconds: 300));

      final state = bloc.state as KeywordManagementLoaded;
      expect(state.keywords, isNot(contains('ma túy')));
      expect(state.keywords.length, 3);
    });

    test('ResetToDefaults restores default keywords', () async {
      bloc.add(const LoadKeywords('family1'));
      await Future.delayed(const Duration(milliseconds: 500));

      bloc.add(const AddKeyword(familyId: 'family1', keyword: 'custom'));
      await Future.delayed(const Duration(milliseconds: 300));

      bloc.add(const ResetToDefaults('family1'));
      await Future.delayed(const Duration(milliseconds: 300));

      final state = bloc.state as KeywordManagementLoaded;
      expect(state.keywords.length, 4);
      expect(state.keywords, isNot(contains('custom')));
    });
  });
}
