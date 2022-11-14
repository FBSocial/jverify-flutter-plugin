#import "JverifyPlugin.h"
#import "JVERIFICATIONService.h"

#define JVLog(fmt, ...) NSLog((@"| JVER | iOS | " fmt), ##__VA_ARGS__)

/// 统一 key
static NSString *const j_result_key = @"result";
/// 错误码
static NSString *const j_code_key = @"code";
/// 回调的提示信息，统一返回 flutter 为 message
static NSString *const j_msg_key = @"message";
/// 默认超时时间
static long j_default_timeout = 5000;
@implementation JverifyPlugin

NSObject<FlutterPluginRegistrar>* _jv_registrar;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"jverify"
                                                              binaryMessenger:[registrar messenger]];
  _jv_registrar = registrar;
  JverifyPlugin* instance = [[JverifyPlugin alloc] init];
  instance.channel = channel;
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    JVLog(@"Action - handleMethodCall: %@",call.method);
    NSString *methodName = call.method;
    if ([methodName isEqualToString:@"setup"]) {
        [self setup:call result:result];
    }else if([methodName isEqualToString:@"setDebugMode"]){
        [self setDebugMode:call result:result];
    }else if([methodName isEqualToString:@"isInitSuccess"]) {
        [self isSetupClient:result];
    }else if([methodName isEqualToString:@"checkVerifyEnable"]){
        [self checkVerifyEnable:call result:result];
    }else if([methodName isEqualToString:@"loginAuth"]){
        [self authorization:call result:result];
    }else if([methodName isEqualToString:@"preLogin"]){
        [self preLogin:call result:result];
    }else if ([methodName isEqualToString:@"getSMSCode"]){
        [self getSMSCode:call result:result];
    }else if ([methodName isEqualToString:@"setGetCodeInternal"]){
        [self setGetCodeInternal:call result:result];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}
#pragma mark -SMS
- (void)getSMSCode:(FlutterMethodCall*) call result:(FlutterResult)resultDict{
    NSDictionary *arguments = call.arguments;
    JVLog(@"Action - getSMSCode:%@",arguments);
    NSString *phoneNumber = arguments[@"phoneNumber"];
    NSString *singId = arguments[@"signId"];
    NSString *tempId = arguments[@"tempId"];
    [JVERIFICATIONService getSMSCode:phoneNumber templateID:tempId signID:singId completionHandler:^(NSDictionary * _Nonnull result) {
        dispatch_async(dispatch_get_main_queue(), ^{
           NSNumber *code = [result objectForKey:@"code"];
           NSString *msg = [result objectForKey:@"msg"];
           NSString *uuid =  [result objectForKey:@"uuid"];
            if ([code intValue] == 3000) {
                NSDictionary*dict = @{@"code":code,@"message":msg,@"result":uuid};
                resultDict(dict);
            }else{
                NSDictionary*dict = @{@"code":code,@"message":msg};
                resultDict(dict);
            }
        });
    }];
}
- (void)setGetCodeInternal:(FlutterMethodCall*) call result:(FlutterResult)resultDict{
    JVLog(@"Action - setGetCodeInternal::");
    NSDictionary *arguments = call.arguments;
    NSNumber *time = arguments[@"timeInterval"];
    [JVERIFICATIONService setGetCodeInternal:[time intValue]];
}
#pragma mark - 设置日志 debug 模式
-(void)setDebugMode:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - setDebugMode::");
    
    NSDictionary *arguments = call.arguments;
    NSNumber *debug = arguments[@"debug"];
    [JVERIFICATIONService setDebug:[debug boolValue]];
}

#pragma mark - 初始化 SDK
- (void)setup:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - setup::");
    NSDictionary *arguments = [call arguments];
    NSString *appKey = arguments[@"appKey"];
    NSString *channel = arguments[@"channel"];
    NSNumber *timeout = arguments[@"timeout"];
    
    JVAuthConfig *config = [[JVAuthConfig alloc] init];
    if (![appKey isKindOfClass:[NSNull class]]) {
        config.appKey = appKey;
    }
    config.appKey =appKey;
    if (![channel isKindOfClass:[NSNull class]]) {
        config.channel = channel;
    }
    if ([timeout isKindOfClass:[NSNull class]]) {
        timeout = @(10000);
    }
    config.timeout = [timeout longLongValue];
    
    __weak typeof(self) weakself = self;
    config.authBlock = ^(NSDictionary *result) {
        JVLog(@"初始化结果 result:%@", result);
        __strong typeof(weakself) strongself = weakself;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *message = result[@"content"];
                   NSString *code = result[@"code"];
                   NSDictionary *dic = @{
                       j_code_key:(code?@([code intValue]):@(0)),
                       j_msg_key:(message?message:@"")
                   };
            //通过 channel 返回
            [strongself.channel invokeMethod:@"onReceiveSDKSetupCallBackEvent" arguments:dic];
        });
    };
    [JVERIFICATIONService setupWithConfig:config];
}

#pragma mark - 获取初始化状态
-(BOOL)isSetupClient:(FlutterResult)result {
    JVLog(@"Action - isSetupClient:");
    BOOL isSetup = [JVERIFICATIONService isSetupClient];
    if (!isSetup) {
        JVLog(@"初始化未完成!");
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        result(@{j_result_key:[NSNumber numberWithBool:isSetup]});
    });
    
    // 初始换成功
    //···
    return isSetup;
}

#pragma mark - 判断网络环境是否支持
-(BOOL)checkVerifyEnable:(FlutterMethodCall*)call result:(FlutterResult)result{
    JVLog(@"Action - checkVerifyEnable::");
    BOOL isEnable = [JVERIFICATIONService checkVerifyEnable];
    if(!isEnable) {
        JVLog(@"当前网络环境不支持认证！");
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        result(@{j_result_key:[NSNumber numberWithBool:isEnable]});
    });
    
    //继续获取token操作
    //...
    return isEnable;
}

#pragma mark - SDK 登录预取号
- (void)preLogin:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - preLogin::%@",call.arguments);
    
    NSDictionary *arguments=  [call arguments];
    NSNumber *timeoutNum = arguments[@"timeout"];
    NSTimeInterval timeout = [timeoutNum longLongValue];
    if (timeout <= 0) {
        timeout = j_default_timeout;
    }
    
    /*
     参数说明:
        completion 预取号结果
            result 字典 key为code和message两个字段
            timeout 超时时间。单位ms，合法范围3000~10000。
     */
    [JVERIFICATIONService preLogin:timeout completion:^(NSDictionary *res) {
        JVLog(@"sdk preLogin completion :%@",res);
        dispatch_async(dispatch_get_main_queue(), ^{
            result(res);
        });
    }];
}

#pragma mark - SDK清除预取号缓存
- (void)clearPreLoginCache:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - clearPreLoginCache::");
    [JVERIFICATIONService clearPreLoginCache];
}


#pragma mark - SDK 请求授权一键登录
- (void)authorization:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - authorization:");
    NSDictionary *arguments=  [call arguments];
    NSNumber *timeoutNum = arguments[@"timeout"];
    NSTimeInterval timeout = [timeoutNum longLongValue];
    if (timeout <= 0) {
        timeout = j_default_timeout;
    }
    [JVERIFICATIONService authorization:timeout completion:^(NSDictionary *res) {
        dispatch_async(dispatch_get_main_queue(), ^{
            result(res);
        });
    }];
}

@end
