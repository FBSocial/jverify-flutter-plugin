//
//  JVERIFICATIONService.h
//  JVerification
//
//  Created by andy on 2018/9/11.
//  Copyright © 2018年 hxhg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define JVER_VERSION_NUMBER 8.2.2

@interface JVAuthConfig : NSObject

/* appKey 必须的,应用唯一的标识. */
@property (nonatomic, copy) NSString *appKey;
/* channel 发布渠道. 可选，默认为空*/
@property (nonatomic, copy) NSString *channel;
/* advertisingIdentifier 广告标识符（IDFA). 可选，默认为空*/
@property (nonatomic, copy) NSString *advertisingId;
/* isProduction 是否生产环境. 如果为开发状态,设置为NO;如果为生产状态,应改为YES.可选，默认为NO */
@property (nonatomic, assign) BOOL isProduction;
/* 设置初始化超时时间，单位毫秒，默认值10s，合法范围是(0,30000]，若非法取默认值推荐设置为5000-10000*/
@property(nonatomic, assign) NSTimeInterval timeout;
/* authBlock 初始化回调*/
@property (nonatomic, copy) void (^authBlock)(NSDictionary *result);
@end


@interface JVERIFICATIONService : NSObject

+ (void)setupWithConfig:(JVAuthConfig *)config;


/**
 获取初始化状态
 * 成功YES, 失败NO
 */
+ (BOOL)isSetupClient;

/**
 获取手机号校验token

 @param completion token相关信息。
 */
+ (void)getToken:(void (^)(NSDictionary *result))completion;

/**
 获取手机号校验token。和+ (void)getToken:(void (^)(NSDictionary *result))completion;实现的功能一致
 @param timeout 超时。单位ms,默认为5000ms。合法范围(0,10000]
 @param completion token相关信息。
 */
+ (void)getToken:(NSTimeInterval)timeout completion:(void (^)(NSDictionary *result))completion;

/**
 授权登录 预取号
 @param timeout 有效取值范围(0,30000],
 若小于等于0或者大于30000则取默认值10000.
 为保证获取预取号结果的成功率，建议设置为3000-5000ms.
 @param completion 预取号结果
 */
+ (void)preLogin:(NSTimeInterval)timeout completion:(void (^)(NSDictionary *result))completion;

/**
 授权登录
 @param timeout 超时有效取值范围(0,30000]，单位ms.
 若小于等于0或者大于30000则取默认值10000.
 为保证获取token的成功率，建议设置为3000-5000ms.
 @param completion 授权登录结果
 */
+ (void)authorization:(NSTimeInterval)timeout completion:(void (^)(NSDictionary *result))completion;

/*!
 * @abstract 设置是否打印sdk产生的Debug级log信息, 默认为NO(不打印log)
 *
 * SDK 默认开启的日志级别为: Info. 只显示必要的信息, 不打印调试日志.
 *
 * 请在SDK启动后调用本接口，调用本接口可打开日志级别为: Debug, 打印调试日志.
 * 请在发布产品时改为NO，避免产生不必要的IO
 */
+ (void)setDebug:(BOOL)enable;

/*!
 * @abstract 判断当前手机网络环境是否可以进行认证
 * 可以认证返回YES, 不能返回NO
 */
+ (BOOL)checkVerifyEnable;

/*!
 * @abstract 清除预取号缓存
 */
+ (void)clearPreLoginCache;

/**
 *  获取短信验证码 （最小间隔时间内只能调用一次）
 *  v2.6.0之后新增接口
 *  @param phoneNumber     手机号码
 *  @param templateID 短信模板ID 如果为nil，则为默认短信签名ID
 *  @param signID  签名ID 如果为nil，则为默认短信签名id
 *  @param handler   block 回调， 成功的时返回的 result 字典包含uuid ,code, msg字段，uuid为此次获取的唯一标识码,  失败时result字段仅返回code ,msg字段
 */
+ (void)getSMSCode:(NSString *)phoneNumber
        templateID:(NSString * _Nullable)templateID
            signID:(NSString * _Nullable)signID
                completionHandler:(void (^_Nonnull)(NSDictionary * _Nonnull result))handler;
/**
 *  设置前后两次获取验证码的时间间隔 ,默认为30000ms （30s），有效间隔 (0,300000）
 *  v8.0.7之后新增接口
 *  在设置间隔时间内只能发送一次获取验证码的请求，SDK 默认是30s
 *  @param intervalTime  时间间隔，单位 ms
 */
+ (void)setGetCodeInternal:(NSTimeInterval)intervalTime;

@end



