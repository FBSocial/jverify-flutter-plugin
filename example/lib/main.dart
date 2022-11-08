import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jverify/jverify.dart';
import 'load.dart';

void main() => runApp(new MaterialApp(
      title: "demo",
      theme: new ThemeData(primaryColor: Colors.white),
      home: MyApp(),
    ));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// 统一 key
  final String f_result_key = "result";

  /// 错误码
  final String f_code_key = "code";

  /// 回调的提示信息，统一返回 flutter 为 message
  final String f_msg_key = "message";

  /// 运营商信息
  final String f_opr_key = "operator";

  String _result = "token=";
  var controllerPHone = new TextEditingController();
  final Jverify jverify = new Jverify();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('JVerify example'),
        ),
        body: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      widthFactor: 2,
      child: new Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(20),
            color: Colors.brown,
            child: Text(_result),
            width: 300,
            height: 100,
          ),
          new Container(
            margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new CustomButton(
                    onPressed: () {
                      isInitSuccess();
                    },
                    title: "初始化状态"),
                new Text("   "),
                new CustomButton(
                  onPressed: () {
                    checkVerifyEnable();
                  },
                  title: "网络环境是否支持",
                ),
              ],
            ),
          ),
          new Container(
            child: TextField(
              autofocus: false,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                  hintText: "手机号码", hintStyle: TextStyle(color: Colors.black)),
              controller: controllerPHone,
            ),
            margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
          ),
          new Container(
            child: SizedBox(
              child: new CustomButton(
                onPressed: () {
                  preLogin();
                },
                title: "预取号",
              ),
              width: double.infinity,
            ),
            margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
          ),
          new Container(
            child: SizedBox(
              child: new CustomButton(
                onPressed: () {
                  jverify.authorization().then((value) {
                    _result = value.toString();
                    print(_result);
                    setState(() {});
                  });
                },
                title: "一键登录",
              ),
              width: double.infinity,
            ),
            margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
          ),
          new Container(
            child: SizedBox(
              child: new CustomButton(
                onPressed: () {
                  getSMSCode();
                },
                title: "获取验证码",
              ),
              width: double.infinity,
            ),
            margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.start,
      ),
    );
  }

  /// sdk 初始化是否完成
  void isInitSuccess() {
    jverify.isInitSuccess().then((map) {
      bool result = map[f_result_key];
      setState(() {
        if (result) {
          _result = "sdk 初始换成功";
        } else {
          _result = "sdk 初始换失败";
        }
      });
    });
  }

  /// 判断当前网络环境是否可以发起认证
  void checkVerifyEnable() {
    jverify.checkVerifyEnable().then((map) {
      bool result = map[f_result_key];
      setState(() {
        if (result) {
          _result = "当前网络环境【支持认证】！";
        } else {
          _result = "当前网络环境【不支持认证】！";
        }
      });
    });
  }

  /// 获取短信验证码
  void getSMSCode() {
    setState(() {
      _showLoading(context);
    });
    String phoneNum = controllerPHone.text;
    if (phoneNum.isEmpty) {
      setState(() {
        _hideLoading();
        _result = "[3002],msg = 没有输入手机号码";
      });
      return;
    }
    jverify.checkVerifyEnable().then((map) {
      bool result = map[f_result_key];
      if (result) {
        jverify.getSMSCode(phoneNum: phoneNum).then((map) {
          print("获取短信验证码：${map.toString()}");
          int code = map[f_code_key];
          String message = map[f_msg_key];
          setState(() {
            _hideLoading();
            _result = "[$code] message = $message";
          });
        });
      } else {
        setState(() {
          _hideLoading();
          _result = "[3004],msg = 获取短信验证码异常";
        });
      }
    });
  }

  /// 登录预取号
  void preLogin() {
    setState(() {
      _showLoading(context);
    });
    jverify.checkVerifyEnable().then((map) {
      bool result = map[f_result_key];
      if (result) {
        jverify.preLogin().then((map) {
          print("预取号接口回调：${map.toString()}");
          int code = map[f_code_key];
          String message = map[f_msg_key];
          setState(() {
            _hideLoading();
            _result = "[$code] message = $message";
          });
        });
      } else {
        setState(() {
          _hideLoading();
          _result = "[2016],msg = 当前网络环境不支持认证";
        });
      }
    });
  }

  void _showLoading(BuildContext context) {
    LoadingDialog.show(context);
  }

  void _hideLoading() {
    LoadingDialog.hidden();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // 初始化 SDK 之前添加监听
    jverify.addSDKSetupCallBackListener((JVSDKSetupEvent event) {
      print("receive sdk setup call back event :${event.toMap()}");
    });

    jverify.setDebugMode(true); // 打开调试模式
    jverify.setup(
        appKey: "", //"你自己应用的 AppKey",
        channel: "devloper-default",
        timeout: 3000); // 初始化sdk,  appKey 和 channel 只对ios设置有效
  }
}

/// 封装 按钮
class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? title;

  const CustomButton({@required this.onPressed, this.title});

  @override
  Widget build(BuildContext context) {
    return new TextButton(
      onPressed: onPressed,
      child: new Text("$title"),
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.white),
        overlayColor: MaterialStateProperty.all(Color(0xff888888)),
        backgroundColor: MaterialStateProperty.all(Color(0xff585858)),
        padding: MaterialStateProperty.all(EdgeInsets.fromLTRB(10, 5, 10, 5)),
      ),
    );
  }
}
