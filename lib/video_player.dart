
import 'data.dart';
import 'package:flutter/material.dart';
import 'package:fijkplayer/fijkplayer.dart';

class VideoListController {

  /// 视频列表
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

  // 更新页面索引
  void changePageViewIndex(target) {
    pageViewIndex = target;
    changeToNextPage?.call(target);
  }

  /// 捕捉滑动，实现翻页
  void setPageContrller(PageController pageController) {
    // 保存
    this.pageController = pageController;
    pageController.addListener(pageEventListener);
  }

  /// 设置播放器
  FijkPlayer setPlayer(String videoUrl, [int targetIndex]) {
    FijkPlayer player;
    player = FijkPlayer()
      ..setDataSource(
        videoUrl,
        // 传递视频索引时默认需要播放视频
        autoPlay: targetIndex != null,
        showCover: true,
      )
      ..setLoop(0);
    return player;
  }

  /// 异步设置播放器
  Future<FijkPlayer> setPlayerAsync(String videoUrl,
      [int targetIndex]) async {
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
    setPageContrller(pageController);
    // 保存父级页面翻页方法
    this.changeToNextPage = changeToNextPage;
    // 初始化视频
    await initVideo(initialList, videoIndex);
  }

  /// 监听事件
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
      int target = p ~/ 1;
      print('sourceIndex索引：$sourceIndex');
      print('目标索引：$target');
      // 未成功翻页
      if (sourceIndex == target) return;
      // 是否需要更新播放资源索引，如果在页面在更新前就已经翻页置为false
      // bool pageChangeRequired = true;
      FijkPlayer player;
      // 先更新索引，防止在未执行视频索引更新时就翻页
      changePageViewIndex(target);
      // 前翻
      if (target < sourceIndex) {
        if (sourceIndex - target == 1) { // 翻一页
          // 销毁最后一个播放器
          playerList[2]?.release();
          playerList[2] = null;
          // 播放当前视频
          player = playerList[0];
          player.start();
          // 如果目标索引不为length - 1
          if (target == 0) {
            playerList.insert(0, null);
          } else {
            playerList.insert(0, setPlayer(sourceList[target - 1].url));
          }
          // 移除最后一项
          playerList.removeLast();
        } else if (sourceIndex - target == 2) { // 翻两页
          // 前两个播放器
          playerList[2]?.release();
          playerList[2] = null;
          playerList[1]?.release();
          playerList[1] = null;
          playerList.removeLast();
          playerList.removeLast();
          player = setPlayer(sourceList[target].url, target);
          playerList.insert(0, player);
          // 如果目标索引不为length - 1
          if (target == 0) {
            playerList.insert(0, null);
          } else {
            playerList.insert(0, setPlayer(sourceList[target - 1].url));
          }
        } else { // 前翻超两页
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
          player = playerList[1] = setPlayer(sourceList[target].url, target);
        }
      } else { // 后翻
        if (target - sourceIndex == 1) { // 只滑动一页的情况
          // 销毁第一个播放器
          playerList[0]?.release();
          playerList[0] = null;
          // 播放当前视频
          player = playerList[2];
          player.start();
          // 如果目标索引不为length - 1
          if (target == sourceList.length - 1) {
            playerList.add(null);
          } else {
            playerList.add(setPlayer(sourceList[target + 1].url));
          }
          // 移除第一项
          playerList.removeAt(0);
        } else if (target - sourceIndex == 2) { // 翻两页
          // 前两个播放器
          playerList[0]?.release();
          playerList[0] = null;
          playerList[1]?.release();
          playerList[1] = null;
          playerList.removeRange(0, 2);
          player = setPlayer(sourceList[target].url, target);
          playerList.add(player);
          // 如果目标索引不为length - 1
          if (target == sourceList.length - 1) {
            playerList.add(null);
          } else {
            playerList.add(setPlayer(sourceList[target + 1].url));
          }
        } else { // 后翻超两页
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
          player = playerList[1] = setPlayer(sourceList[target].url, target);
        }
      }
      // 更新索引
      sourceIndex = target;
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
