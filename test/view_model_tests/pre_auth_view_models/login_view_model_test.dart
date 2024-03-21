// ignore_for_file: talawa_api_doc
// ignore_for_file: talawa_good_doc_comments

// import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
// import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:talawa/constants/routing_constants.dart';
import 'package:talawa/locator.dart';
// import 'package:talawa/constants/routing_constants.dart';
// import 'package:talawa/locator.dart';
import 'package:talawa/models/organization/org_info.dart';
import 'package:talawa/models/user/user_info.dart';
import 'package:talawa/services/user_config.dart';
import 'package:talawa/utils/queries.dart';
import 'package:talawa/view_model/pre_auth_view_models/login_view_model.dart';

import '../../helpers/test_helpers.dart';
// import 'package:talawa/utils/queries.dart';
// import 'package:talawa/view_model/pre_auth_view_models/login_view_model.dart';

// import '../../helpers/test_helpers.dart';

final data = {
  'login': {
    'user': {
      '_id': 'xzy1',
      'firstName': 'Test',
      'lastName': 'User',
      'email': 'testuser@gmail.com',
    },
    'accessToken': 'testtoken',
    'refreshToken': 'testtoken',
  },
};

bool empty = false;

Future<void> main() async {
  // setupFirebaseMocks();
  // await Firebase.initializeApp();
  // FirebaseMessagingPlatform.instance = kMockMessagingPlatform;

  setUp(() async {
    locator.registerSingleton(Queries());
    registerServices();
    await locator.unregister<UserConfig>();
  });
  tearDown(() async {
    await locator.unregister<Queries>();
  });

  group('LoginViewModel Test -', () {
    testWidgets(
        'Check if login() is working fine when organisation is not empty',
            (tester) async {
          locator.registerSingleton<UserConfig>(MockUserConfig());

          final model = LoginViewModel();

          await tester.pumpWidget(
            Form(
              key: model.formKey,
              child: Container(),
            ),
          );

          final result = QueryResult(
            source: QueryResultSource.network,
            data: data,
            options: QueryOptions(document: gql(queries.loginUser('', ''))),
          );

          when(databaseFunctions.gqlNonAuthMutation(queries.loginUser('', '')))
              .thenAnswer((_) async => result);

          await model.login();
          expect(model.validate, AutovalidateMode.disabled);
          verify(databaseFunctions.gqlNonAuthMutation(queries.loginUser('', '')));
        });
    testWidgets('Check if login() is working fine when organisation empty',
            (tester) async {
          empty = true;
          locator.registerSingleton<UserConfig>(MockUserConfig());

          final model = LoginViewModel();

          await tester.pumpWidget(
            Form(
              key: model.formKey,
              child: Container(),
            ),
          );

          final result = QueryResult(
            source: QueryResultSource.network,
            data: data,
            options: QueryOptions(document: gql(queries.loginUser('', ''))),
          );

          when(databaseFunctions.gqlNonAuthMutation(queries.loginUser('', '')))
              .thenAnswer((_) async => result);

          await model.login();
          expect(model.validate, AutovalidateMode.disabled);
          verify(databaseFunctions.gqlNonAuthMutation(queries.loginUser('', '')));
        });
    testWidgets('Check if login() is working fine when invalid credentials',
            (tester) async {
          reset(navigationService);
          final model = LoginViewModel();

          await tester.pumpWidget(
            Form(
              key: model.formKey,
              child: Container(),
            ),
          );

          when(databaseFunctions.gqlNonAuthMutation(queries.loginUser('', '')))
              .thenAnswer((_) async => null);

          await model.login();
          expect(model.validate, AutovalidateMode.disabled);
          verify(databaseFunctions.gqlNonAuthMutation(queries.loginUser('', '')));
          verifyNever(
            navigationService.removeAllAndPush(
              Routes.waitingScreen,
              Routes.splashScreen,
            ),
          );
        });
    testWidgets('Check if login() is working fine when throws error',
            (tester) async {
          final model = LoginViewModel();

          await tester.pumpWidget(
            Form(
              key: model.formKey,
              child: Container(),
            ),
          );

          when(databaseFunctions.gqlNonAuthMutation(queries.loginUser('', '')))
              .thenThrow(Exception());

          await model.login();
          expect(model.validate, AutovalidateMode.disabled);
          verify(databaseFunctions.gqlNonAuthMutation(queries.loginUser('', '')));
        });

    // **NEW TESTS**

    // test for validation for empty email and password
    testWidgets('Check form validation for empty email and password',
            (tester) async {
          final model = LoginViewModel();

          await tester.pumpWidget(
            Form(
              key: model.formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: model.email,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Email is required';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: model.password,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          );

          // Submit form without entering any values
          await model.login();

          expect(model.validate, AutovalidateMode.always);
        });

    // Test for initializing greeting message
    test('Initialize greeting message', () {
      final model = LoginViewModel();
      model.initialize();

      expect(model.greeting.length, 4);
    });

    // Test for unfocusing text fields
    testWidgets('Unfocus text fields after login', (tester) async {
      final model = LoginViewModel();
      model.emailFocus.requestFocus();
      model.passwordFocus.requestFocus();

      // Simulate successful login
      await model.login();

      expect(model.emailFocus.hasFocus, false);
      expect(model.passwordFocus.hasFocus, false);
    });


  });
}

class MockUserConfig extends Mock implements UserConfig {
  @override
  User get currentUser => User(
    joinedOrganizations: empty
        ? []
        : [
      OrgInfo(
        id: '3',
        name: 'test org 3',
        userRegistrationRequired: false,
        creatorInfo: User(firstName: 'test', lastName: '1'),
      ),
    ],
  );

  @override
  Future<bool> updateUser(User user) async => true;
}
