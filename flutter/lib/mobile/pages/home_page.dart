import 'package:flutter/material.dart';
import 'package:flutter_hbb/mobile/pages/server_page.dart';
import '../../common.dart';

// 保留全局 Key 防止其他底层逻辑找不到页面报错
class HomePage extends StatefulWidget {
  static final homeKey = GlobalKey<HomePageState>();

  HomePage() : super(key: homeKey);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  // 保留刷新方法空壳，防止外部调用报错
  void refreshPages() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // 允许工人按手机返回键正常退出软件
          return true; 
        },
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            // 顶部标题，读取默认的应用名称
            title: Text(bind.mainGetAppNameSync()), 
          ),
          // ⚠️ 核心杀招：没有任何底部分页栏，直接把“服务端(被控)页面”强行塞满整个屏幕！
          body: ServerPage(),
        ));
  }
}

// ⚠️ 彻底掏空 Web 端的废代码，只留一个空壳防止编译报错，极限压缩包体！
class WebHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
