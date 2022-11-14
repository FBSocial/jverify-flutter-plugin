package com.jiguang.jverify;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.StateListDrawable;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import cn.jiguang.verifysdk.api.AuthPageEventListener;
import cn.jiguang.verifysdk.api.JVerificationInterface;
import cn.jiguang.verifysdk.api.JVerifyUIClickCallback;
//import cn.jiguang.verifysdk.api.JVerifyUIConfig;
import cn.jiguang.verifysdk.api.LoginSettings;
import cn.jiguang.verifysdk.api.PreLoginListener;
import cn.jiguang.verifysdk.api.RequestCallback;
import cn.jiguang.verifysdk.api.VerifyListener;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


/**
 * JverifyPlugin
 */
public class JverifyPlugin implements FlutterPlugin, MethodCallHandler {

    // 定义日志 TAG
    private static final String TAG = "| JVER | Android | -";


    /// 统一 key
    private static String j_result_key = "result";
    /// 错误码
    private static String j_code_key = "code";
    /// 回调的提示信息，统一返回 flutter 为 message
    private static String j_msg_key = "message";
    /// 运营商信息
    private static String j_opr_key = "operator";
    // 默认超时时间
    private static int j_default_timeout = 5000;
    // 重复请求
    private static int j_error_code_repeat = -1;


    private Context context;
    private MethodChannel channel;


    @Override
    public void onAttachedToEngine(FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "jverify");
        channel.setMethodCallHandler(this);
        context = flutterPluginBinding.getApplicationContext();
    }


    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }


    @Override
    public void onMethodCall(MethodCall call, Result result) {
        Log.d(TAG, "onMethodCall:" + call.method);

        Log.d(TAG, "processMethod:" + call.method);
        if (call.method.equals("setup")) {
            setup(call, result);
        } else if (call.method.equals("setDebugMode")) {
            setDebugMode(call, result);
        } else if (call.method.equals("isInitSuccess")) {
            isInitSuccess(call, result);
        } else if (call.method.equals("checkVerifyEnable")) {
            checkVerifyEnable(call, result);
        } else if (call.method.equals("preLogin")) {
            preLogin(call, result);
        } else if (call.method.equals("loginAuth")) {
            loginAuth(call, result);
        } else if (call.method.equals("loginAuthSyncApi")) {
            loginAuthSyncApi(call, result);
        } else if (call.method.equals("clearPreLoginCache")) {
            clearPreLoginCache(call, result);
        } else {
            result.notImplemented();
        }
    }


    // 主线程再返回数据
    private void runMainThread(final Map<String, Object> map, final Result result, final String method) {
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
            @Override
            public void run() {
                if (result == null && method != null) {
                    channel.invokeMethod(method, map);
                } else {
                    result.success(map);
                }
            }
        });
    }


    /**
     * SDK 初始换
     */
    private void setup(MethodCall call, Result result) {
        Log.d(TAG, "Action - setup:");

        Object timeout = getValueByKey(call, "timeout");
        boolean setControlWifiSwitch = (boolean) getValueByKey(call, "setControlWifiSwitch");
        if (!setControlWifiSwitch) {
            Log.d(TAG, "Action - setup: setControlWifiSwitch==" + false);
            setControlWifiSwitch();
        }

        JVerificationInterface.init(context, (Integer) timeout, new RequestCallback<String>() {
            @Override
            public void onResult(int code, String message) {
                Map<String, Object> map = new HashMap<>();
                map.put(j_code_key, code);
                map.put(j_msg_key, message);
                // 通过 channel 返回
                runMainThread(map, null, "onReceiveSDKSetupCallBackEvent");
            }
        });
    }

    private void setControlWifiSwitch() {
        try {
            Class<JVerificationInterface> aClass = JVerificationInterface.class;
            Method method = aClass.getDeclaredMethod("setControlWifiSwitch", boolean.class);
            method.setAccessible(true);
            method.invoke(aClass, false);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    /**
     * SDK设置debug模式
     */
    private void setDebugMode(MethodCall call, Result result) {
        Log.d(TAG, "Action - setDebugMode:");
        Object enable = getValueByKey(call, "debug");
        if (enable != null) {
            JVerificationInterface.setDebugMode((Boolean) enable);
        }

        Map<String, Object> map = new HashMap<>();
        map.put(j_result_key, enable);
        runMainThread(map, result, null);
    }

    /**
     * 获取 SDK 初始化是否成功标识
     */
    private boolean isInitSuccess(MethodCall call, Result result) {
        Log.d(TAG, "Action - isInitSuccess:");
        boolean isSuccess = JVerificationInterface.isInitSuccess();
        if (!isSuccess) {
            Log.d(TAG, "SDK 初始化失败: ");
        }

        Map<String, Object> map = new HashMap<>();
        map.put(j_result_key, isSuccess);
        runMainThread(map, result, null);

        return isSuccess;
    }

    /**
     * SDK 判断网络环境是否支持
     */
    private boolean checkVerifyEnable(MethodCall call, Result result) {
        Log.d(TAG, "Action - checkVerifyEnable:");
        boolean verifyEnable = JVerificationInterface.checkVerifyEnable(context);
        if (!verifyEnable) {
            Log.d(TAG, "当前网络环境不支持");
        }

        Map<String, Object> map = new HashMap<>();
        map.put(j_result_key, verifyEnable);
        runMainThread(map, result, null);

        return verifyEnable;
    }

    /**
     * SDK 一键登录预取号
     */
    private void preLogin(final MethodCall call, final Result result) {
        Log.d(TAG, "Action - preLogin:" + call.arguments);

        int timeOut = j_default_timeout;
        if (call.hasArgument("timeOut")) {
            timeOut = call.argument("timeOut");
        }

        JVerificationInterface.preLogin(context, timeOut, new PreLoginListener() {
            @Override
            public void onResult(int code, String content, String operator, String securityNum) {
                if (code == 7000) {//code: 返回码，7000代表获取成功，其他为失败，详见错误码描述
                    Log.d(TAG, "verify success, message =" + content);
                } else {
                    Log.e(TAG, "verify fail，code=" + code + ", message =" + content);
                }
                Map<String, Object> map = new HashMap<>();
                map.put(j_code_key, code);
                map.put(j_msg_key, content);

                runMainThread(map, result, null);
            }
        });
    }


    /**
     * SDK清除预取号缓存
     */
    private void clearPreLoginCache(MethodCall call, final Result result) {
        Log.d(TAG, "Action - clearPreLoginCache:");
        JVerificationInterface.clearPreLoginCache(context);
    }


    /**
     * SDK请求授权一键登录，异步
     */
    private void loginAuth(MethodCall call, final Result result) {
        Log.d(TAG, "Action - loginAuth:");
        loginAuthInterface(false, call, result);
    }

    /**
     * SDK请求授权一键登录，同步
     */
    private void loginAuthSyncApi(MethodCall call, final Result result) {
        Log.d(TAG, "Action - loginAuthSyncApi:");
        loginAuthInterface(true, call, result);
    }

    private void loginAuthInterface(final Boolean isSync, final MethodCall call, final Result result) {
        Log.d(TAG, "Action - loginAuthInterface:");
        int timeOut = call.argument("timeout");

        JVerificationInterface.loginAuth(context, timeOut, new VerifyListener() {
            @Override
            public void onResult(int code, String content, String operator) {
                if (code == 6000) {
                    Log.d(TAG, "code=" + code + ", token=" + content + " ,operator=" + operator);
                } else {
                    Log.d(TAG, "code=" + code + ", message=" + content);
                }
                Map<String, Object> map = new HashMap<>();
                map.put(j_code_key, code);
                map.put(j_msg_key, content);
                map.put(j_opr_key, operator);
                if (isSync) {
                    // 通过 channel 返回
                    runMainThread(map, null, "onReceiveLoginAuthCallBackEvent");
                } else {
                    // 通过回调返回
                    runMainThread(map, result, null);
                }
            }
        });
    }


    private Object getValueByKey(MethodCall call, String key) {
        if (call != null && call.hasArgument(key)) {
            return call.argument(key);
        } else {
            return null;
        }
    }


}
