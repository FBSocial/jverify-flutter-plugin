import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/*
 * SDK 初始接口回调监听
 *
 * @param event
 *          code     ：返回码，8000代表初始化成功，其他为失败，详见错误码描述
 *          message  ：返回码的解释信息，若获取成功，内容信息代表loginToken。
 *
 * @discussion 调用 setup 接口后，可以通过添加此监听事件来监听接口的返回结果
 * */
typedef JVSDKSetupCallBackListener = void Function(JVSDKSetupEvent event);

class JVEventHandlers {
  static final JVEventHandlers _instance = new JVEventHandlers._internal();

  JVEventHandlers._internal();

  factory JVEventHandlers() => _instance;
  JVSDKSetupCallBackListener? sdkSetupCallBackListener;
}

class Jverify {
  static const String flutter_log = "| JVER | Flutter | ";

  /// 错误码
  static const String j_flutter_code_key = "code";

  /// 回调的提示信息
  static const String j_flutter_msg_key = "message";

  /// 重复请求
  static const int j_flutter_error_code_repeat = -1;

  factory Jverify() => _instance;
  final JVEventHandlers _eventHanders = new JVEventHandlers();

  final MethodChannel _channel;
  final List<String> requestQueue = [];

  @visibleForTesting
  Jverify.private(MethodChannel channel) : _channel = channel;

  static final _instance = new Jverify.private(const MethodChannel("jverify"));

  /// SDK 初始化回调监听
  addSDKSetupCallBackListener(JVSDKSetupCallBackListener? callback) {
    _eventHanders.sdkSetupCallBackListener = callback;
  }

  Future<void> _handlerMethod(MethodCall call) async {
    debugPrint("handleMethod method = ${call.method}");
    switch (call.method) {
      case 'onReceiveSDKSetupCallBackEvent':
        {
          if (_eventHanders.sdkSetupCallBackListener != null) {
            Map json = call.arguments.cast<dynamic, dynamic>();
            JVSDKSetupEvent event = JVSDKSetupEvent.fromJson(json);
            _eventHanders.sdkSetupCallBackListener!(event);
          }
        }
        break;
      default:
        throw new UnsupportedError("Unrecognized Event");
    }
    return;
  }

  Map<dynamic, dynamic>? isRepeatRequest({required String method}) {
    bool isContain = requestQueue.any((element) => (element == method));
    if (isContain) {
      Map map = {
        j_flutter_code_key: j_flutter_error_code_repeat,
        j_flutter_msg_key: method + " is requesting, please try again later."
      };
      debugPrint(flutter_log + map.toString());
      return map;
    } else {
      requestQueue.add(method);
      return null;
    }
  }

  /// 初始化, timeout单位毫秒，合法范围是(0,30000]，推荐设置为5000-10000,默认值为10000
  void setup(
      {@required String? appKey,
      String? channel,
      bool? useIDFA,
      int timeout = 10000,
      bool setControlWifiSwitch = true}) {
    debugPrint("$flutter_log" + "setup");

    _channel.setMethodCallHandler(_handlerMethod);

    _channel.invokeMethod("setup", {
      "appKey": appKey,
      "channel": channel,
      "useIDFA": useIDFA,
      "timeout": timeout,
      "setControlWifiSwitch": setControlWifiSwitch
    });
  }

  /// 设置 debug 模式
  void setDebugMode(bool debug) {
    debugPrint("$flutter_log" + "setDebugMode");
    _channel.invokeMethod("setDebugMode", {"debug": debug});
  }

  ///设置前后两次获取验证码的时间间隔，默认 30000ms，有效范围(0,300000)
  void setGetCodeInternal(int intervalTime) {
    debugPrint("$flutter_log" + "setGetCodeInternal");
    _channel.invokeMethod("setGetCodeInternal", {"timeInterval": intervalTime});
  }

/*
   * SDK 获取短信验证码
   *
   * return Map
   *        key = "code", vlaue = 状态码，3000代表获取成功
   *        key = "message", 提示信息
   *        key = "result",uuid
   * */
  Future<Map<dynamic, dynamic>> getSMSCode(
      {@required String? phoneNum, String? signId, String? tempId}) async {
    debugPrint("$flutter_log" + "getSMSCode");

    var args = <String, String>{};
    if (phoneNum != null) {
      args["phoneNumber"] = phoneNum;
    }

    if (signId != null) {
      args["signId"] = signId;
    }

    if (tempId != null) {
      args["tempId"] = tempId;
    }

    return await _channel.invokeMethod("getSMSCode", args);
  }

  /*
   * 获取 SDK 初始化是否成功标识
   *
   * return Map
   *          key = "result"
   *          vlue = bool,是否成功
   * */
  Future<Map<dynamic, dynamic>> isInitSuccess() async {
    debugPrint("$flutter_log" + "isInitSuccess");
    return await _channel.invokeMethod("isInitSuccess");
  }

  /*
   * SDK判断网络环境是否支持
   *
   * return Map
   *          key = "result"
   *          vlue = bool,是否支持
   * */
  Future<Map<dynamic, dynamic>> checkVerifyEnable() async {
    debugPrint("$flutter_log" + "checkVerifyEnable");
    return await _channel.invokeMethod("checkVerifyEnable");
  }

  /*
   * SDK 一键登录预取号,timeOut 有效取值范围[3000,10000]
   *
   * return Map
   *        key = "code", vlaue = 状态码，7000代表获取成功
   *        key = "message", value = 结果信息描述
   * */
  Future<Map<dynamic, dynamic>> preLogin({int timeOut = 10000}) async {
    var para = new Map();
    if (timeOut >= 3000 && timeOut <= 10000) {
      para["timeOut"] = timeOut;
    }
    debugPrint("$flutter_log" + "preLogin" + "$para");

    String method = "preLogin";
    var repeatError = isRepeatRequest(method: method);
    if (repeatError == null) {
      var result = await _channel.invokeMethod(method, para);
      requestQueue.remove(method);
      return result;
    } else {
      return repeatError;
    }
  }

  /*
  * SDK 清除预取号缓存
  *
  * @discussion 清除 sdk 当前预取号结果缓存
  *
  * @since v2.4.3
  * */
  void clearPreLoginCache() {
    debugPrint("$flutter_log" + "clearPreLoginCache");
    _channel.invokeMethod("clearPreLoginCache");
  }

  /*
  授权登录
  @param timeout 超时有效取值范围(0,30000]，单位ms.
  若小于等于0或者大于30000则取默认值10000.
  为保证获取token的成功率，建议设置为3000-5000ms.
  @param completion 授权登录结果
 */

  Future<Map?> authorization({int timeOut = 10000}) async {
    var para = Map();
    if (timeOut >= 3000 && timeOut <= 10000) {
      para["timeOut"] = timeOut;
    }
    debugPrint("$flutter_log" + "loginAuth" + "$para");

    String method = "loginAuth";
    var repeatError = isRepeatRequest(method: method);
    if (repeatError == null) {
      var result = await _channel.invokeMethod(method, para);
      requestQueue.remove(method);
      return result;
    } else {
      return repeatError;
    }
  }
}

/// 监听返回类
class JVListenerEvent {
  int?
      code; //返回码，具体事件返回码请查看（https://docs.jiguang.cn/jverification/client/android_api/）
  String? message; //事件描述、事件返回值等
  String? operator; //成功时为对应运营商，CM代表中国移动，CU代表中国联通，CT代表中国电信。失败时可能为null

  JVListenerEvent.fromJson(Map<dynamic, dynamic> json)
      : code = json['code'],
        message = json['message'],
        operator = json['operator'];

  Map toMap() {
    return {'code': code, 'message': message, 'operator': operator};
  }
}

/// 授权页事件
class JVAuthPageEvent extends JVListenerEvent {
  @override
  JVAuthPageEvent.fromJson(Map<dynamic, dynamic> json) : super.fromJson(json);

  @override
  Map toMap() {
    return {
      'code': code,
      'message': message,
    };
  }
}

/// SDK 初始化回调事件
class JVSDKSetupEvent extends JVAuthPageEvent {
  @override
  JVSDKSetupEvent.fromJson(Map<dynamic, dynamic> json) : super.fromJson(json);
}
