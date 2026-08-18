import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: RemoteApp()));
}

class RemoteApp extends StatefulWidget {
  const RemoteApp({super.key});
  @override
  State<RemoteApp> createState() => _RemoteAppState();
}

class _RemoteAppState extends State<RemoteApp> {
  final TextEditingController _ipCtrl = TextEditingController(text: "YOUR_VPS_IP");
  final TextEditingController _portCtrl = TextEditingController(text: "8080");
  WebSocketChannel? _ws;
  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  MediaStream? _stream;
  bool _running = false;
  String _info = "就绪";

  Future<void> _start() async {
    try {
      setState(() => _info = "连接 WebSocket...");
      _ws = WebSocketChannel.connect(Uri.parse('ws://${_ipCtrl.text}:${_portCtrl.text}'));
      _pc = await createPeerConnection({'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]});

      _dc = await _pc?.createDataChannel('control', RTCDataChannelInit());
      _dc?.onMessage = (msg) => print("[收到坐标]: ${msg.text}");

      _pc?.onIceCandidate = (c) => _ws?.sink.add(jsonEncode({'type': 'candidate', 'candidate': c.toMap()}));

      _ws?.stream.listen((msg) async {
        final data = jsonDecode(msg);
        if (data['type'] == 'answer') {
          await _pc?.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
        } else if (data['type'] == 'candidate') {
          await _pc?.addIceCandidate(RTCIceCandidate(data['candidate']['candidate'], data['candidate']['sdpMid'], data['candidate']['sdpMLineIndex']));
        }
      });

      setState(() => _info = "请求录屏...");
      _stream = await navigator.mediaDevices.getDisplayMedia({'audio': false, 'video': {'mandatory': {'frameRate': 30}}});
      _stream?.getTracks().forEach((t) => _pc?.addTrack(t, _stream!));

      RTCSessionDescription offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      _ws?.sink.add(jsonEncode(offer.toMap()));
      setState(() { _running = true; _info = "推流中"; });
    } catch (e) {
      setState(() => _info = "错误: $e");
    }
  }

  void _stop() {
    _stream?.getTracks().forEach((t) => t.stop());
    _pc?.close();
    _ws?.sink.close();
    setState(() { _running = false; _info = "已停止"; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('被控端 MVP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _ipCtrl, decoration: const InputDecoration(labelText: 'VPS IP')),
          TextField(controller: _portCtrl, decoration: const InputDecoration(labelText: '端口')),
          const SizedBox(height: 20),
          Text('状态: $_info'),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _running ? _stop : _start, child: Text(_running ? '停止' : '开始共享'))
        ]),
      ),
    );
  }
}
