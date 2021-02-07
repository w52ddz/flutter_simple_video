import 'package:flutter/material.dart';
import 'package:video_test_project/video_player/video.dart';

import 'inherited_widget/inherited_widget_page.dart';

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
  void _navigateTo(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView(
        children: [
          FlatButton(
            onPressed: () => _navigateTo(VideoPage()),
            child: Text('视频页'),
          ),
          Divider(
            color: Colors.red,
          ),
          FlatButton(
            onPressed: () => _navigateTo(InheritedWidgetTestRoute()),
            child: Text('inheritedWidget'),
          ),
        ],
      ),
    );
  }
}
