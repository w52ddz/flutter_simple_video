import 'data.dart';
import 'package:flutter/material.dart';
import 'package:fijkplayer/fijkplayer.dart';

/* 分支dev-2：同步滑动，由于player同步生成，会出现下面问题：
  1. 向上或向下翻一页时会先展示暂停按钮
  2. 翻页超过一页时，player未准备好，会先展示黑屏，之后才能正常展示
 */
class VideoListController {
  /// 视频列表，视频上限为3
  List<FijkPlayer> playerList = [null, null, null];

  /// 所在的数据列表的序号
  int sourceIndex = 0;

  /// 记录当前pageView的索引
  int pageViewIndex = 0;

  /// 获取3个播放器
  FijkPlayer get currentPlayer => playerList[1];
  FijkPlayer get prevPlayer => playerList[0];
  FijkPlayer get nextPlayer => playerList[2];

  bool get isPlaying => currentPlayer.state == FijkState.started;

  /// 获取指定index的player
  FijkPlayer playerOfIndex(int index) => playerList[index];

  /// 视频总数目
  int get videoCount => playerList.length;

  /// 数据列表
  List<UserVideo> sourceList = [];

  PageController pageController;
  // 保存父级的索引跟新方法
  Function changeToNextPage;
  Function refreshUI; // 刷新ui界面

  // 更新页面索引
  void changePageViewIndex(target) {
    pageViewIndex = target;
    changeToNextPage?.call(target);
  }

  /// 捕捉滑动，实现翻页
  void setPageController(PageController pageController) {
    // 保存
    this.pageController = pageController;
    pageController.addListener(pageEventListener);
  }

  /// 设置播放器
  FijkPlayer setPlayer(String videoUrl, [int targetIndex]) {
    FijkPlayer player;
    bool autoPlay = targetIndex != null;
    player = FijkPlayer()
      ..setDataSource(
        videoUrl,
        // 传递视频索引时默认需要播放视频
        autoPlay: autoPlay,
        showCover: true,
      )
      ..setLoop(0);
    return player;
  }

  // 异步设置播放器资源，并播放
  Future<void> asynclySetPlayer(FijkPlayer player, String videoUrl) async {
    await player.setDataSource(
      videoUrl,
      autoPlay: true,
      showCover: true,
    );
    await player.setLoop(0);
  }

  /// 异步设置播放器
  Future<FijkPlayer> setPlayerAsync(String videoUrl, [int targetIndex]) async {
    FijkPlayer player = FijkPlayer();
    await player.setDataSource(
      videoUrl,
      autoPlay: true,
      showCover: true,
    );
    await player.setLoop(0);
    /* bool canPlay = true;
    // 此时该视频已划走
    if (targetIndex != null && targetIndex != pageViewIndex) {
      canPlay = false;
    }
    // 视频页未被销毁前，app在前台才执行播放操作
    if (canPlay/*  && AppLifecycleState.resumed == Global.appLifecycleState */) {
      // await player.start();
    } */
    return player;
  }

  /// 视频初始化
  Future<void> initVideo(List<UserVideo> list, int videoIndex) async {
    sourceList.clear();
    playerList = [null, null, null];
    if (list.length == 0) return;
    // 添加至数据列表
    sourceList.addAll(list);
    // 数据列表中的序号
    sourceIndex = videoIndex; // 传递索引时播放对应索引的视频
    pageViewIndex = sourceIndex;
    // 添加当前索引对应的视频
    if (sourceIndex - 1 >= 0) {
      playerList[0] = setPlayer(list[sourceIndex - 1].url);
    }
    if (sourceIndex + 1 <= list.length - 1) {
      playerList[2] = setPlayer(list[sourceIndex + 1].url);
    }
    playerList[1] = await setPlayerAsync(list[sourceIndex].url, sourceIndex);
  }

  /// 初始化
  Future<void> init({
    PageController pageController,
    List<UserVideo> initialList,
    int videoIndex = 0, // 默认播放的视频索引
    Function changeToNextPage, // 翻页
    Function refreshUI, // 刷新主页面
  }) async {
    // 绑定controller事件
    setPageController(pageController);
    // 父级页面刷新方法
    this.refreshUI = refreshUI;
    // 保存父级页面翻页方法
    this.changeToNextPage = changeToNextPage;
    // 初始化视频
    await initVideo(initialList, videoIndex);
  }

  /// 页面滑动监听事件
  void pageEventListener() async {
    double p = pageController.page;
    // 当前视频完全划走就暂停
    if ((p - sourceIndex).abs() >= 1) {
      // 暂停并重置正在播放的视频
      if (currentPlayer?.value?.duration != null) {
        currentPlayer?.seekTo(0);
      }
      currentPlayer?.pause();
    }
    if (p % 1 == 0) {
      // 目标页
      int target = p ~/ 1;
      print('sourceIndex索引：$sourceIndex');
      print('目标索引：$target');
      // 未成功翻页
      if (sourceIndex == target) return;
      // 是否需要更新父级播放资源索引，如果在页面在更新前就已经翻页置为false
      bool pageChangeRequired = true;
      // 用户保存将要播放视频的播放器
      FijkPlayer player;
      // 先更新索引
      pageViewIndex = target;
      // 前翻
      if (target < sourceIndex) {
        if (sourceIndex - target == 1) {
          // 翻一页
          // 销毁最后一个播放器
          playerList[2]?.release();
          playerList[2] = null;
          // 如果目标索引不为length - 1
          playerList.insert(
              0, target == 0 ? null : setPlayer(sourceList[target - 1].url));
          // 移除最后一项
          playerList.removeLast();
          // 播放当前视频
          player = playerList[1];
          await player.start();
        } else if (sourceIndex - target == 2) {
          // 翻两页
          // 前两个播放器
          playerList[2]?.release();
          playerList[2] = null;
          playerList[1]?.release();
          playerList[1] = null;
          // 删除后两个
          playerList.removeRange(1, 3);
          // 向前填充
          playerList.insertAll(0, [null, null]);
          // 如果目标索引不为length - 1
          if (target != 0) {
            playerList[0] = setPlayer(sourceList[target - 1].url);
          }
          player = playerList[1] = FijkPlayer();
          await asynclySetPlayer(player, sourceList[target].url);
        } else {
          // 前翻超两页
          // 全部销毁
          playerList.forEach((FijkPlayer fijkPlayer) {
            fijkPlayer?.release();
            fijkPlayer = null;
          });
          playerList[2] = setPlayer(sourceList[target + 1].url);
          // 如果目标索引不为0
          if (target != 0) {
            playerList[0] = setPlayer(sourceList[target - 1].url);
          }
          player = playerList[1] = FijkPlayer();
          await asynclySetPlayer(player, sourceList[target].url);
        }
      } else {
        // 后翻
        if (target - sourceIndex == 1) {
          // 只滑动一页的情况
          // 销毁第一个播放器
          playerList[0]?.release();
          playerList[0] = null;
          // 如果目标索引不为length - 1
          if (target == sourceList.length - 1) {
            playerList.add(null);
          } else {
            playerList.add(setPlayer(sourceList[target + 1].url));
          }
          // 移除第一项
          playerList.removeAt(0);
          // 播放当前视频
          player = playerList[1];
          await player.start();
        } else if (target - sourceIndex == 2) {
          // 翻两页
          // 前两个播放器
          playerList[0]?.release();
          playerList[0] = null;
          playerList[1]?.release();
          playerList[1] = null;
          // 删除前两个播放器
          playerList.removeRange(0, 2);
          // 向后填充
          playerList.addAll([null, null]);
          // 如果目标索引不为length - 1
          if (target != sourceList.length - 1) {
            playerList[2] = setPlayer(sourceList[target + 1].url);
          }
          player = playerList[1] = FijkPlayer();
          await asynclySetPlayer(player, sourceList[target].url);
        } else {
          // 后翻超两页
          // 全部销毁
          playerList.forEach((FijkPlayer fijkPlayer) {
            fijkPlayer?.release();
            fijkPlayer = null;
          });
          playerList[0] = setPlayer(sourceList[target - 1].url);
          // 如果目标索引不为length - 1
          if (target != sourceList.length - 1) {
            playerList[2] = setPlayer(sourceList[target + 1].url);
          }
          player = playerList[1] = FijkPlayer();
          await asynclySetPlayer(player, sourceList[target].url);
        }
      }
      print('是否需要更-------------------新索引$pageChangeRequired');
      // 如果视频准备好播放时已经划走
      if (pageViewIndex != target) {
        print(
            '有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有有没有');
        player?.pause();
        if ((pageViewIndex - target).abs() > 1) {
          player?.dispose();
        }
        pageChangeRequired = false;
      }
      if (pageChangeRequired) {
        // 更新索引
        sourceIndex = target;
        // 同步更新父级索引
        changePageViewIndex(target);
      }
    }
  }

  /// 销毁全部
  void dispose() {
    for (FijkPlayer player in playerList) {
      player?.release();
    }
    playerList = [null, null, null];
    sourceList.clear();
    pageController?.removeListener(pageEventListener);
    pageController.dispose();
  }
}
