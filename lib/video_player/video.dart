import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
import 'package:video_test_project/video_player/data.dart';
import 'package:video_test_project/video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> with WidgetsBindingObserver {
  PageController _pageController = PageController();
  int currentPageIndex = 0;
  List<UserVideo> list = [];
  VideoListController videoListController;

  // 滑动视频切换页面索引
  void changeToNextPage(index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  void refreshUI() {
    if (mounted) setState(() {});
  }

  void initVideoListController() async {
    // 初始化
    videoListController = VideoListController();
    await videoListController.init(
      pageController: _pageController,
      initialList: list,
      changeToNextPage: changeToNextPage,
      refreshUI: refreshUI,
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
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state != AppLifecycleState.resumed) {
      videoListController.currentPlayer.pause();
    }
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
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            pageSnapping: true,
            physics: ClampingScrollPhysics(),
            scrollDirection: Axis.vertical,
            itemCount: list.length,
            itemBuilder: (context, i) {
              // UserVideo data = list[i];
              // 索引对应的播放器
              FijkPlayer player;
              if (i == currentPageIndex) {
                player = videoListController.currentPlayer;
              } else if (currentPageIndex - 1 >= 0 &&
                  i == currentPageIndex - 1) {
                player = videoListController.prevPlayer;
              } else if (currentPageIndex - 1 <= list.length &&
                  i == currentPageIndex + 1) {
                player = videoListController.nextPlayer;
              }
              // 是否显示暂停按钮- 当前视频状态不为paused且索引不为当前索引
              bool showPauseIcon = false;
              if (player != null) {
                showPauseIcon =
                    i == currentPageIndex && player.state == FijkState.paused;
              }
              return GestureDetector(
                onTap: () async {
                  if (player == null) return;
                  FijkState fijkState = player.state;
                  if (fijkState == FijkState.started) {
                    await player.pause();
                  } else if (fijkState == FijkState.paused) {
                    await player.start();
                  }
                  setState(() {});
                },
                child: Stack(
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
                              panelBuilder: (_, __, ___, ____, _____) =>
                                  Container(),
                            ),
                    ),
                    // 暂停
                    // showPauseIcon ? AnimatedPause() : Container(),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.arrow_back_ios),
            iconSize: 50,
            color: Colors.red,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class AnimatedPause extends StatefulWidget {
  @override
  _AnimatedPauseState createState() => _AnimatedPauseState();
}

class _AnimatedPauseState extends State<AnimatedPause>
    with TickerProviderStateMixin {
  AnimationController animationController;
  Animation animation;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(duration: Duration(milliseconds: 150), vsync: this);
    animation = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 2.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50),
    ]).animate(animationController)
      ..addListener(() {
        this.setState(() {});
      });
    animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      alignment: Alignment.center,
      child: Transform.scale(
        scale: double.parse('${animation.value}'),
        child: Opacity(
          opacity: double.parse('${1 - (animation.value - 1)}'),
          child: Image.asset(
            'images/video_pause_icon.png',
            width: 48.52,
            height: 60,
          ),
        ),
      ),
    );
  }
}
