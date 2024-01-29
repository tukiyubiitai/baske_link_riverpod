import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers/account/account_state_notifier.dart';
import '../../state/providers/team/team_post_provider.dart';
import '../../widgets/modal_sheet.dart';
import '../../widgets/progress_indicator.dart';
import '../../widgets/teams/team_post_items.dart';

class TeamRecruitmentPage extends ConsumerWidget {
  const TeamRecruitmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamPostDataAsyncValue = ref.watch(teamPostNotifierProvider);
    final accountState = ref.watch(accountStateNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.indigo[900],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigoAccent,
        onPressed: () {
          showModalBottomSheet<String>(
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return StatefulBuilder(
                  builder: (BuildContext context, Function setSheetState) {
                return ModalBottomSheetContent(
                  type: 'team',
                );
              });
            },
          );
        },
        child: const Icon(Icons.manage_search),
      ),
      body: Column(
        children: [
          Expanded(
            child: teamPostDataAsyncValue.when(
              loading: () => const ShowProgressIndicator(
                textColor: Colors.white,
                indicatorColor: Colors.white,
              ),
              error: (e, stack) => Text('エラーが発生しました: $e'),
              data: (teamPostData) {
                if (teamPostData.posts.isEmpty) {
                  return const Center(
                    child: Text(
                      '投稿がありません',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: teamPostData.posts.length,
                  itemBuilder: (BuildContext context, int index) {
                    final post = teamPostData.posts[index];
                    final user = teamPostData.users[index];

                    // return teamPostData != null
                    //     ?
                    return TeamPostItem(
                      postId: post.id,
                      postData: post,
                      userData: user,
                    );
                    // : const Center(
                    //     child: Text(
                    //       'ユーザー情報が見つかりません',
                    //       style: TextStyle(color: Colors.white),
                    //     ),
                    //   );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}