import 'package:basketball_app/models/auth/auth_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers/auth/auth_notifier.dart';
import '../../state/providers/global_loader.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/progress_indicator.dart';
import '../account/create_account_page.dart';
import 'sign_in_screen.dart';

class LoginAndSignupPage extends ConsumerWidget {
  const LoginAndSignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsyncValue = ref.watch(authStateNotifierProvider);
    final loader = ref.watch(globalLoaderProvider); // ローディング状態を監視

    return Scaffold(
      backgroundColor: Colors.indigo[900],
      body: authAsyncValue.when(
        error: (e, stack) {
          debugPrint(e.toString());
          return Center(child: Text('エラーが発生しました: $e'));
        },
        loading: () => ShowProgressIndicator(
          textColor: Colors.white,
          indicatorColor: Colors.white,
        ),
        data: (status) {
          switch (status) {
            case AuthStatus.unauthenticated:
              //サインイン表示
              return SignInScreen(loader: loader, ref: ref);
            case AuthStatus.accountNotCreated:
              //アカウント作成ページ
              return CreateAccount();
            case AuthStatus.authenticated:
              //タイムラインページ
              return BottomTabNavigator(initialIndex: 0, userId: '');
          }
        },
      ),
    );
  }
}