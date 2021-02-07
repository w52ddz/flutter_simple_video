import 'package:flutter/material.dart';

class InheritedWidgetTestRoute extends StatefulWidget {
  @override
  _InheritedWidgetTestRouteState createState() =>
      _InheritedWidgetTestRouteState();
}

class _InheritedWidgetTestRouteState extends State<InheritedWidgetTestRoute> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('inherited widget'),
      ),
      body: Center(
        // ShareDataWidget继承自InheritedWidget，接受count作为共享数据data
        child: ShareDataWidget(
          data: count,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                //注册了依赖关系的_TextWidget,获取共享数据并展示在Text中
                child: TextWidget(),
              ),
              RaisedButton(
                child: Text("增加"),
                //更新数据
                onPressed: () => setState(() => ++count),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ShareDataWidget extends InheritedWidget {
  ShareDataWidget({@required this.data, Widget child}) : super(child: child);

  final int data;

  // 这个方法可以不定义，在子组件调用的时候直接调用
  // 定义of()静态方法，方便子widget获取自身数据，且一旦调用即注册了与之依赖的关系
  static ShareDataWidget of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShareDataWidget>();
  }

  // 这个方法必须重写决定是否通知注册了的子widget
  @override
  bool updateShouldNotify(ShareDataWidget old) {
    // 这里的通知策略是由data是否改变决定是否通知
    return old.data != data;
  }
}

class TextWidget extends StatefulWidget {
  @override
  _TextWidgetState createState() => _TextWidgetState();
}

class _TextWidgetState extends State<TextWidget> {
  @override
  Widget build(BuildContext context) {
    // 如果ShareDataWidget的of方法不定义，调用方式可以改为
    ShareDataWidget shareDataWidget =
        context.dependOnInheritedWidgetOfExactType<ShareDataWidget>();
    int _newdata = shareDataWidget.data;
    // 调用ShareDataWidget.of()注册对应Widget的依赖关系并获得data
    // int _newdata = ShareDataWidget.of(context).data;
    // 以Text组件返回共享数据
    return Text(_newdata.toString());
  }

  @override
  // 此方法一般不需要重写，这里是为了展示收到通知并更新的过程
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("Dependencies 生命周期");
  }
}
