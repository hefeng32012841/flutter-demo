import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/services.dart';
//import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  Permission.microphone.request();

  runApp(MyInAppWebView());
}

Future<void> requestMicrophonePermission() async {
  var status = await Permission.microphone.status;
  if (!status.isGranted) {
    await Permission.microphone.request();
  }
}

class MyInAppWebView extends StatefulWidget {
  @override
  _MyInAppWebViewState createState() => new _MyInAppWebViewState();
}

class _MyInAppWebViewState extends State<MyInAppWebView> {
  InAppWebViewController? webView;
  RTCPeerConnection? peerConnection;
  MediaStream? _localStream;
  final Map<String, dynamic> config = {
    'sdpSemantics': 'unified-plan',
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ]
  };

  final Map<String, dynamic> constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  static const platform = MethodChannel('com.example.audio');

  Future<void> changeAudioOutput(String output) async {
    try {
      await platform.invokeMethod('changeAudioOutput', {"output": output});
    } on PlatformException catch (e) {
      print("Failed to change audio output: ${e.message}");
    }
  }

  @override
  void initState() {
    super.initState();
  }


  Future<void> createRTC() async {
    peerConnection = await createPeerConnection(config, constraints);
    //changeAudioOutput('speaker');

    peerConnection?.onTrack = (RTCTrackEvent e) async {
      var stream = e.streams[0];
      print("来自Web的消息 onTrack: ${e}");

      print('Audio tracks: ${stream.getAudioTracks()}');
      for (var track in stream.getAudioTracks()) {
        print('Track enabled: ${track.enabled}');
        print('Track label: ${track.label}');
        print('Track kind: ${track.kind}');
        print('Track: ${track}');
      }
      //final RTCVideoRenderer audioRenderer = RTCVideoRenderer();
      //_localStream = stream;
      //if (stream.getAudioTracks().isNotEmpty) {

      //  // 获取音频轨
      //  MediaStreamTrack audioTrack = stream.getAudioTracks().first;
      //  print("来自native的消息 非空: ${audioTrack}");

      //  // 处理音频轨，例如显示音量条或者创建一个新的 UI 组件
      //  // 注意：音频会自动播放，不需要额外的视频或音频组件
      //}
      //// Do something with the received audio stream
      //// await audioRenderer.initialize();
      //await audioRenderer.initialize();
      //audioRenderer.srcObject = stream;
      //// MediaStreamTrack audioTrack = stream.getAudioTracks().first;
      //// audioTrack.onEnded = void (e) {
      ////
      //// }
      //// if (audioTrack != null) {
      ////   audioTrack.enabled = true;
      ////   print("来自Web的消息 onAddStream: ${audioTrack.toString()}");
      // }
    };

    peerConnection?.onIceCandidate = (e) {
      if (e.candidate != null) {
        Map<String, dynamic> candidateMap = {
          'candidate': e.candidate,
          'sdpMid': e.sdpMid,
          'sdpMLineIndex': e.sdpMLineIndex,
        };

        String jsonString = json.encode(candidateMap);
        print("来自fluter的消息 onIceCandidate: ${jsonString}");
        sendMessageToWebView(jsonString);
      }
    };
  }

  void closeRTC() async {
    _localStream?.dispose();
    _localStream = null;
    await peerConnection?.close();
    peerConnection = null;
  }

  void sendMessageToWebView(String params) async {
    await webView?.evaluateJavascript(
      source: "window.receiveMessageFromFlutter('${params}');",
    );
  }

  Future<Map<String, dynamic>> remoteOffer(Map offer) async {
    if (peerConnection == null) {
      await createRTC();
    }
    print("开始 remoteOffer");
    RTCSessionDescription description = RTCSessionDescription(
      offer['sdp'],
      offer['type'],
    );
    await peerConnection?.setRemoteDescription(description);

    dynamic answer = await peerConnection?.createAnswer({'offerToReceiveAudio': true, 'offerToReceiveVideo': false});
    await peerConnection?.setLocalDescription(answer);
    Map<String, dynamic> sessionDescriptionMap = {
      'sdp': answer.sdp,
      'type': answer.type,
    };
    return sessionDescriptionMap;
    print("结束 remoteOffer");
  }

  void remoteAddIceCandidate(Map candidateJson) async {
    print("开始 remoteAddIceCandidate");
    RTCIceCandidate candidate = RTCIceCandidate(
      candidateJson['candidate'],
      candidateJson['sdpMid'],
      candidateJson['sdpMLineIndex'],
    );
    await peerConnection?.addCandidate(candidate);
    print("结束 remoteAddIceCandidate");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          color: Colors.blue, // 根据需求设置颜色
          height: 50, // 设置 header 的高度
          // 其他你希望放置在 header 中的 Widget...
        ),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr, //或者 TextDirection.rtl，根据你的需求
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri("https://echo.amap.test/tech-center/sdk-manage/demo?version=1.0.8&mobile=1")),
              //initialUrlRequest: URLRequest(url: Uri.parse("https://agent-5.cticloud.cn/pre-test/webrtc-pre-test.html")),
              initialSettings: InAppWebViewSettings(
                isInspectable: kDebugMode,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                iframeAllow: "microphone",
                iframeAllowFullscreen: true,
                allowBackgroundAudioPlaying: true
              ),
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT);
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                dynamic url = navigationAction.request.url ?? '';
                if (![
                  "http",
                  "https",
                  "file",
                  "chrome",
                  "data",
                  "javascript",
                  "about"
                ].contains(url.scheme ?? '')) {
                  if (await canLaunchUrl(url)) {
                    // Launch the App
                    await launchUrl(
                      url,
                    );
                    // and cancel the request
                    return NavigationActionPolicy.CANCEL;
                  }
                }
                return NavigationActionPolicy.ALLOW;
              },
              onWebViewCreated: (InAppWebViewController controller) {
                webView = controller;
                controller.addJavaScriptHandler(
                  handlerName: 'createRTC',
                  callback: (List<dynamic> args) {
                    try {
                      Map data = json.decode(args[0]);
                      // 这里是JavaScript消息传递到Flutter端的处理代码
                      print("来自Web的消息 createRTC: ${data}");
                      return remoteOffer(data);
                    } catch(err) {
                      print("错误: ${err}");
                    }
                  },
                );

                controller.addJavaScriptHandler(
                  handlerName: 'addIceCandidate',
                  callback: (List<dynamic> args) {
                    try {
                      // 这里是JavaScript消息传递到Flutter端的处理代码
                      Map data = json.decode(args[0]);
                      print("来自Web的消息 addIceCandidate: ${data}");
                      remoteAddIceCandidate(data);
                    } catch(err) {
                      print("错误: ${err}");
                    }
                  },
                );

                controller.addJavaScriptHandler(
                  handlerName: 'closeRTC',
                  callback: (List<dynamic> args) {
                    try {
                      print("来自Web的消息 closeRTC");
                      closeRTC();
                    } catch(err) {
                      print("错误: ${err}");
                    }
                  },
                );
              },
              onLoadStop: (controller, url) async {
                
              },
              // 在这里处理证书错误
              onReceivedServerTrustAuthRequest: (controller, challenge) async {
                return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
              },
            )
          ),
        ),
      ],
    );
  }
}