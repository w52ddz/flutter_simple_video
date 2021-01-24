import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
import 'package:video_test_project/data.dart';
import 'package:video_test_project/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material Components',
      home: OuterContainer(),
    );
  }
}

class OuterContainer extends StatefulWidget {
  @override
  _OuterContainerState createState() => _OuterContainerState();
}

class _OuterContainerState extends State<OuterContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        child: Center(
          child: FlatButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => HomePage())),
            child: Text('video page'),
          ),
        ),
      );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  PageController _pageController = PageController();
  int currentPageIndex = 0;
  List<UserVideo> list = [];
  VideoListController videoListController;

  // 滑动视频切换页面索引
  changeToNextPage(index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  void initVideoListController() async {
    // 初始化
    videoListController = VideoListController();
    await videoListController.init(
      pageController: _pageController,
      initialList: list,
      changeToNextPage: changeToNextPage,
    );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    list = [
      UserVideo(image: '', url: mockVideo, desc: '罗永浩'),
      UserVideo(image: '', url: mV2, desc: 'MV_TEST_2'),
      UserVideo(image: '', url: mV3, desc: 'MV_TEST_3'),
      UserVideo(image: '', url: mV4, desc: 'MV_TEST_4'),
      UserVideo(image: '', url: mockVideo, desc: '罗永浩'),
      UserVideo(image: '', url: mV2, desc: 'MV_TEST_2'),
      UserVideo(image: '', url: mV3, desc: 'MV_TEST_3'),
      UserVideo(image: '', url: mV4, desc: 'MV_TEST_4'),
    ];
    initVideoListController();
  }

  @override
  void dispose() {
    super.dispose();
    print('页面销毁');
    videoListController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          child: PageView.builder(
            controller: _pageController,
            pageSnapping: true,
            physics: ClampingScrollPhysics(),
            scrollDirection: Axis.vertical,
            itemCount: list.length,
            itemBuilder: (context, i) {
              UserVideo data = list[i];
              // 索引对应的播放器
              FijkPlayer player;
              if (i == currentPageIndex) {
                player = videoListController.currentPlayer;
              } else if (currentPageIndex - 1 >= 0 && i == currentPageIndex - 1) {
                player = videoListController.prevPlayer;
              } else if (currentPageIndex - 1 <= list.length && i == currentPageIndex + 1) {
                player = videoListController.nextPlayer;
              }
              // 是否显示暂停按钮- 当前视频状态不为paused且索引不为当前索引
              bool showPauseIcon = false;
              if (player != null) {
                showPauseIcon = i == currentPageIndex
                  && player.state == FijkState.paused;
              }
              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: player == null
                      ? Center(
                        child: Text('占位图片'),
                      )
                      : FijkView(
                        fit: FijkFit.fitHeight,
                        player: player,
                        color: Colors.black,
                        panelBuilder: (_, __, ___, ____, _____) => Container(),
                      ),
                  )
                ],
              );
            },
          ),
        )
      );
  }
}