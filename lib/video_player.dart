
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
    // 保存播放器
    this.pageController = pageController;
    pageController.addListener(pageEventListener);
  }

  /// 设置播放器
  FijkPlayer setPlayer(String videoUrl, [int targetIndex]) {
    FijkPlayer player;
    player = FijkPlayer()
      ..setDataSource(
        videoUrl,
        showCover: true,
      )
      ..setLoop(0);
    // 防止视频还未准备完成就翻页
    if (targetIndex != null && targetIndex == sourceIndex) {
      player.start();
    }
    return player;
  }

  /// 异步设置播放器
  Future<FijkPlayer> setPlayerAsync(String videoUrl,
      [int targetIndex]) async {
    FijkPlayer player = FijkPlayer();
    await player.setDataSource(
      videoUrl,
      // autoPlay: true,
      showCover: true,
    );
    await player.setLoop(0);
    bool canPlay = true;
    // 此时该视频已划走
    if (targetIndex != null && targetIndex != pageViewIndex) {
      canPlay = false;
    }
    // 视频页未被销毁前，app在前台才执行播放操作
    if (canPlay/*  && AppLifecycleState.resumed == Global.appLifecycleState */) {
      // await player.start();
    }
    return player;
  }

  /// 视频初始化
  Future<void> initVideo(List<UserVideo> list, int videoIndex) async {
    sourceList = [];
    playerList = [null, null, null];
    if (list.length == 0) return;
    // 添加至数据列表
    sourceList.addAll(list);
    // 数据列表中的序号
    sourceIndex = videoIndex; // 传递索引时播放对应索引的视频
    pageViewIndex = sourceIndex;
    // 添加当前索引对应的视频
    playerList[1] = await setPlayerAsync(list[sourceIndex].url);
    if (sourceIndex - 1 >= 0) {
      playerList[0] = setPlayer(list[sourceIndex - 1].url);
    }
    if (sourceIndex + 1 <= list.length - 1) {
      playerList[2] = setPlayer(list[sourceIndex + 1].url);
    }
  }

  /// 初始化
  Future<void> init({
    PageController pageController,
    List<UserVideo> initialList,
    int videoIndex = 0, // 默认播放的视频索引
    Function changeToNextPage, // 翻页
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
      bool pageChangeRequired = true;
      FijkPlayer player;
      // 先更新索引，防止在未执行视频索引更新时就翻页
      changePageViewIndex(target);
      // 前翻
      if (target < sourceIndex) {
        // 销毁最后一个播放器
        playerList[2]?.dispose();
        playerList[2] = null;
        // 如果连续滑动超过1页，就不能直接使用playerList中的原数据，全部需要更新
        if (sourceIndex - target > 1) {
          // 全部销毁
          playerList.asMap().keys.forEach((index) {
            playerList[index]?.dispose();
            playerList[index] = null;
          });
          playerList[2] = setPlayer(sourceList[target + 1].url);
          // 如果目标索引不为0，设置第一个播放器
          if (target != 0) {
            playerList[0] = setPlayer(sourceList[target - 1].url);
          }
          player = playerList[1] = await setPlayerAsync(sourceList[target].url, target);
        } else { // 正常只滑动一页的情况
          // 如果目标索引不为0，设置第一个播放器
          if (target != 0) {
            playerList[0] = setPlayer(sourceList[target - 1].url);
          }
          player = playerList[target];
          await player.start();
        }
      } else { // 后烦
        // 销毁最后一个播放器
        playerList[0]?.dispose();
        playerList[0] = null;
        // 后翻超过1页
        if (target - sourceIndex > 1) {
          // 全部销毁
          playerList.asMap().keys.forEach((index) {
            playerList[index]?.dispose();
            playerList[index] = null;
          });
          playerList[0] = setPlayer(sourceList[target - 1].url);
          // 如果目标索引不为length - 1
          if (target != sourceList.length - 1) {
            playerList[2] = setPlayer(sourceList[target + 1].url);
          }
          player = playerList[1] = await setPlayerAsync(sourceList[target].url, target);
        } else { // 正常只滑动一页的情况
          // 如果目标索引不为length - 1
          if (target != sourceList.length - 1) {
            playerList[2] = setPlayer(sourceList[target + 1].url);
          }
          player = playerList[target];
          await player.start();
        }
      }
      // 如果视频准备好播放时已经划走
      if (pageViewIndex != target) {
        player?.pause();
        if ((pageViewIndex - target).abs() > 1) {
          player?.dispose();
        }
        pageChangeRequired = false;
      }
      if (pageChangeRequired) {
        sourceIndex = target;
      }
    }
  }

  /// 销毁全部
  void dispose() {
    print('player 销毁');
    for (var player in playerList) {
      player?.dispose();
    }
    playerList = [null, null, null];
    sourceList = [];
    pageController?.removeListener(pageEventListener);
  }
}
