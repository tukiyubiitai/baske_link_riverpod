import 'package:basketball_app/widgets/map/court_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../repository/map_repository.dart';
import '../../state/providers/map/map_provider.dart';
import '../progress_indicator.dart';

class ListSection extends ConsumerStatefulWidget {
  const ListSection({super.key});

  @override
  ConsumerState<ListSection> createState() => _ListSectionState();
}

class _ListSectionState extends ConsumerState<ListSection> {
  late int _currentIndex;
  late PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    _currentIndex = 0; // PageView の初期表示ページを設定

    // PageViewの表示を切り替えるのに使う
    _pageController = PageController(
        initialPage: _currentIndex,
        viewportFraction: 0.85); //0.85くらいで端っこに別のカードが見えてる感じになる
  }

  @override
  Widget build(BuildContext context) {
    final mapStateNotifier = ref.watch(mapProvider);

    //マーカーがタップされた時に、その番号に該当するPageViewまでスクロールする
    Future<void> scrollToSelectedPage(int selectedPage) async {
      await _pageController.animateToPage(
        selectedPage,
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );
    }

    final int? selectIndex = mapStateNotifier.selectCourt; //タップされたマーカーの番号が入る
    if (selectIndex != null) {
      if (_pageController.hasClients) {
        //その番号に該当するPageViewまでスクロールする
        scrollToSelectedPage(selectIndex);
      }
    }

    return Container(
      height: 148,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: PageView(
        onPageChanged: (int index) async {
          final zoomLevel =
              await mapStateNotifier.mapController!.getZoomLevel();
          final selectedCourt = selectIndex != null
              ? mapStateNotifier.markers.values
                  .elementAt(selectIndex) //マーカーがタップされた時の処理
              : mapStateNotifier.markers.values
                  .elementAt(index); //PageViewがスワップされた通常時の処理
          mapStateNotifier
              .clearSelect(); //mapProvider.selectCourt(タップされたマーカーの番号)をnullに戻す

          //スワイプ後のcourtの座標までカメラを移動
          mapStateNotifier.mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(selectedCourt.position.latitude,
                    selectedCourt.position.longitude),
                zoom: zoomLevel,
              ),
            ),
          );
          final mapController = mapStateNotifier.mapController;
          if (mapController != null) {
            //mapにマーカーを表示させる
            await mapController.showMarkerInfoWindow(selectedCourt.markerId);
          }
        },
        controller: _pageController,
        children: _buildCourtCard(), // ページビュー内のカードウィジェットを生成
      ),
    );
  }

  List<Widget> _buildCourtCard() {
    final mapStateNotifier = ref.read(mapProvider);
    return List.generate(
      mapStateNotifier.markers.length, //取得したマーカーの数
      (index) {
        final marker = mapStateNotifier.markers.values.toList()[index];
        final imageUrl = mapStateNotifier.urls[index].toString();
        final courtAddress = mapStateNotifier.addressList[index];
        // double? courtPositionLatitude;
        // double? courtPositionLongitude;
        // カードウィジェットを生成
        return mapStateNotifier.loading
            ? Container(
                height: 148,
                child: Center(
                    child: CircularProgressIndicator(
                  color: Colors.blue,
                )))
            : Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0), // カード全体の角丸を指定
                ),
                child: SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      // 画像の表示部分
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15.0), // 左上の角丸を指定
                          bottomLeft: Radius.circular(15.0), // 左下の角丸を指定
                        ),
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return ShowProgressIndicator(
                                indicatorColor: Colors.blue,
                              );
                            },
                            errorBuilder: (BuildContext context, Object error,
                                StackTrace? stackTrace) {
                              return Text('画像の読み込みに失敗しました');
                            },
                          ),
                        ),
                      ),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              // タイトルテキストの表示
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  marker.infoWindow.title.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 3,
                                  softWrap: true,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                // 詳細ボタンがタップされた時の処理
                                mapStateNotifier.clearBodyUrls();
                                final tappedMarker = marker;
                                final placeId = tappedMarker.markerId.value;
                                await MapRepository()
                                    .fetchDetailPhoto(placeId, ref);
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(25.0),
                                    ),
                                  ),
                                  builder: (BuildContext context) {
                                    return CourtDetailSheet(
                                        imageUrl: imageUrl,
                                        courtAddress: courtAddress,
                                        marker: marker,
                                        ref: ref);
                                    // return SizedBox(
                                    //   width: double.infinity,
                                    //   child: Column(
                                    //     children: [
                                    //       const SizedBox(
                                    //         height: 30,
                                    //       ),
                                    //       Padding(
                                    //         padding: const EdgeInsets.symmetric(
                                    //             horizontal: 20.0),
                                    //         child: Text(
                                    //           marker.infoWindow.title
                                    //               .toString(),
                                    //           style: const TextStyle(
                                    //             fontSize: 20,
                                    //             fontWeight: FontWeight.bold,
                                    //           ),
                                    //           maxLines: 3,
                                    //           softWrap: true,
                                    //         ),
                                    //       ),
                                    //       Row(
                                    //         mainAxisAlignment:
                                    //             MainAxisAlignment.spaceAround,
                                    //         children: [
                                    //           // シェアボタン
                                    //           _buildIconButtonWithText(
                                    //             Icons.share,
                                    //             "シェアする",
                                    //             () async {
                                    //               await MapViewModel()
                                    //                   .shareImage(
                                    //                       imageUrl,
                                    //                       marker
                                    //                           .infoWindow.title
                                    //                           .toString());
                                    //             },
                                    //           ),
                                    //           // Googleマップで開くボタン
                                    //           _buildIconButtonWithText(
                                    //             Icons.navigation,
                                    //             "google mapで開く",
                                    //             () async {
                                    //               await MapViewModel()
                                    //                   .handleUrlAction(
                                    //                       courtPositionLatitude!,
                                    //                       courtPositionLongitude!,
                                    //                       context,
                                    //                       ref);
                                    //             },
                                    //           ),
                                    //           // お気に入りボタン
                                    //           _buildIconButtonWithText(
                                    //             Icons.favorite,
                                    //             "お気に入り",
                                    //             () {
                                    //               Navigator.of(context).pop();
                                    //               showSnackBar(
                                    //                 context: context,
                                    //                 text:
                                    //                     'ごめんなさい。その機能は開発中です(T . T)',
                                    //                 backgroundColor:
                                    //                     Colors.indigo,
                                    //                 textColor: Colors.white,
                                    //               );
                                    //             },
                                    //           ),
                                    //         ],
                                    //       ),
                                    //       const SizedBox(
                                    //         height: 20,
                                    //       ),
                                    //       // コートの場所の住所
                                    //       _buildCourtLocation(courtAddress),
                                    //       const SizedBox(
                                    //         height: 20,
                                    //       ),
                                    //       // コートの写真を表示
                                    //       _buildPhotoPageView(context),
                                    //     ],
                                    //   ),
                                    // );
                                  },
                                );
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.orange),
                              ),
                              child: const Text(
                                "詳細",
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
      },
    );
  }
}
