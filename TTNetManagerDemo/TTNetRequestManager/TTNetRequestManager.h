//
//  TTNetRequestManager.h
//  TTNetManagerDemo
//
//  Created by TAO on 2017/9/29.
//  Copyright © 2017年 Billow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TTNetRequestCache.h"

#ifndef IsHasNet
#define IsHasNet    [TTNetRequestManager tt_isHasNetwork]  // 一次性判断是否有网的宏
#endif

#ifndef IsHasWWAN 
#define IsHasWWAN   [TTNetRequestManager tt_isHasWWAN]  // 一次性判断是否为手机网络的宏
#endif

#ifndef IsHasWiFi
#define IsHasWiFi   [TTNetRequestManager tt_isHasWiFi]  // 一次性判断是否为WiFi网络的宏
#endif

#pragma mark - 枚举

typedef NS_ENUM(NSUInteger, TTNetworkStatusType) {
    TTNetworkStatusType_UnKnow = 1,  // 未知网络
    TTNetworkStatusType_NotNet,      // 无网络
    TTNetworkStatusType_WWAN,        // 手机网络
    TTNetworkStatusType_WiFi,        // wifi网络
};

typedef NS_ENUM(NSUInteger, TTResponseSerializer) {
    TTResponseSerializer_JSON,  // 设置响应数据为JSON 格式
    TTResponseSerializer_HTTP,  // 设置响应数据为二进制格式
};

typedef NS_ENUM(NSUInteger, TTRequestSerializer) {
    TTRequestSerializer_JSON,  // 设置请求数据为JSON 格式
    TTRequestSerializer_HTTP,  // 设置请求数据为二进制格式
};

#pragma mark - Block

typedef void(^TTRequestSuccess)(id responseObject);          // 请求成功的Block
typedef void(^TTRequestFailure)(NSError *error);             // 请求失败的Block
typedef void(^TTRequestCache)(id responseCache);             // 缓存的Block
typedef void(^TTRequestPropress)(NSProgress *progress);      // 上传或下载进度Block
typedef void(^TTNetworkStatus)(TTNetworkStatusType status);  // 网络状态的Block

@class AFHTTPSessionManager;

@interface TTNetRequestManager : NSObject

#pragma mark - 网络判断及回调状态

/**
 *  是否有WiFi网络
 *
 *  @return YES - 有, NO - 无
 */
+ (BOOL)tt_isHasWiFi;

/**
 *  是否有手机网络
 *
 *  @return YES - 有, NO - 无
 */
+ (BOOL)tt_isHasWWAN;

/**
 *  是否有网
 *
 *  @return YES - 有网, NO - 无网
 */
+ (BOOL)tt_isHasNetwork;

/**
 *  实时获取网络状态, 通过Block回调实时获取(可多次调用)
 *
 *  @param networkStatus 网络状态的Block
 */
+ (void)tt_networkStatusWithBlock:(TTNetworkStatus)networkStatus;

/**
 *  取消所有网络请求
 */
+ (void)tt_cancelAllRequest;

/**
 *  取消指定URL的请求
 *
 *  @param urlStr 指定的URL
 */
+ (void)tt_cancelRequestWithURL:(NSString *)urlStr;

/**
 *  开启日志打印（debug）
 */
+ (void)tt_openLog;

/**
 *  关闭日志打印, 默认关
 */
+ (void)tt_closeLog;

#pragma mark - 网络请求

/**
 *  GET请求, 无缓存
 *
 *  @param urlStr         请求的地址
 *  @param parameters     请求的参数
 *  @param requestSuccess 请求成功的回调
 *  @param requestFailure 请求失败的回调
 *
 *  @return 返回的对象可取消请求, 调用cancel方法
 */
+ (NSURLSessionTask *)GET:(NSString *)urlStr
               parameters:(id)parameters
                  success:(TTRequestSuccess)requestSuccess
                  failure:(TTRequestFailure)requestFailure;
/**
 *  GET请求, 自动缓存
 *
 *  @param urlStr         请求的地址
 *  @param parameters     请求的参数
 *  @param requestCache   缓存数据的回调
 *  @param requestSuccess 请求成功的回调
 *  @param requestFailure 请求失败的回调
 *
 *  @return 返回的对象可取消请求, 调用cancel方法
 */
+ (NSURLSessionTask *)GET:(NSString *)urlStr
               parameters:(id)parameters
            responseCache:(TTRequestCache)requestCache
                  success:(TTRequestSuccess)requestSuccess
                  failure:(TTRequestFailure)requestFailure;
/**
 *  POST请求, 无缓存
 *
 *  @param urlStr         请求的地址
 *  @param parameters     请求的参数
 *  @param requestSuccess 请求成功的回调
 *  @param requestFailure 请求失败的回调
 *
 *  @return 返回的对象可取消请求, 调用cancel方法
 */
+ (NSURLSessionTask *)POST:(NSString *)urlStr
                parameters:(id)parameters
                   success:(TTRequestSuccess)requestSuccess
                   failure:(TTRequestFailure)requestFailure;
/**
 *  POST请求, 自动缓存
 *
 *  @param urlStr         请求的地址
 *  @param parameters     请求的参数
 *  @param requestCache   缓存数据的回调
 *  @param requestSuccess 请求成功的回调
 *  @param requestFailure 请求失败的回调
 *
 *  @return 返回的对象可取消请求, 调用cancel方法
 */
+ (NSURLSessionTask *)POST:(NSString *)urlStr
                parameters:(id)parameters
             responseCache:(TTRequestCache)requestCache
                   success:(TTRequestSuccess)requestSuccess
                   failure:(TTRequestFailure)requestFailure;
/**
 *  上传文件
 *
 *  @param urlStr          请求的地址
 *  @param parameters      请求的参数
 *  @param fileName        文件对应服务器的字段
 *  @param filePath        文本本地的沙盒路径
 *  @param requestProgress 上传进度的回调
 *  @param requestSuccess  请求成功的回调
 *  @param requestFailure  请求失败的回调
 *
 *  @return 返回的对象可取消请求, 调用cancel方法
 */
+ (NSURLSessionTask *)tt_uploadFileWithURL:(NSString *)urlStr
                                parameters:(id)parameters
                                  fileName:(NSString *)fileName
                                  filePath:(NSString *)filePath
                                  progress:(TTRequestPropress)requestProgress
                                   success:(TTRequestSuccess)requestSuccess
                                   failure:(TTRequestFailure)requestFailure;
/**
 *  上传单/多张图片
 *
 *  @param urlStr          请求的地址
 *  @param parameters      请求的参数
 *  @param imageName       图片对应服务器的字段
 *  @param images          图片数组
 *  @param fileNames       图片文件名数组, 可以为nil, 数组内的文件名默认为当前日期 "yyyyMMddHHmmss"
 *  @param imageScale      图片文件压缩比, 范围（0.f ~ 1.f）
 *  @param imageType       图片文件的类型, png、jpg(默认)
 *  @param requestProgress 请求进度的回调
 *  @param requestSuccess  请求成功的回调
 *  @param requestFailure  请求失败的回调
 *
 *  @return 返回的对象可取消请求, 调用cancel方法
 */
+ (NSURLSessionTask *)tt_uploadImagesWithURL:(NSString *)urlStr
                                  parameters:(id)parameters
                                   imageName:(NSString *)imageName
                                      images:(NSArray<UIImage *> *)images
                                   fileNames:(NSArray<NSString *> *)fileNames
                                  imageScale:(CGFloat)imageScale
                                   imageType:(NSString *)imageType
                                    progress:(TTRequestPropress)requestProgress
                                     success:(TTRequestSuccess)requestSuccess
                                     failure:(TTRequestFailure)requestFailure;
/**
 *  文件下载
 *
 *  @param urlStr          下载地址
 *  @param fileDir         下载文件存储目录（默认问Download）
 *  @param requestProgress 下载进度的回调
 *  @param requestSuccess  下载成功的回调
 *  @param requestFailure  下载失败的回调
 *
 *  @return 返回NSURLSessionDownloadTask实例，可用于暂停继续，暂停调用suspend方法，开始下载调用resume方法
 */
+ (NSURLSessionTask *)tt_downloadWithURL:(NSString *)urlStr
                                 fileDir:(NSString *)fileDir
                                progress:(TTRequestPropress)requestProgress
                                 success:(TTRequestSuccess)requestSuccess
                                 failure:(TTRequestFailure)requestFailure;

#pragma mark - AFHTTPSessionManager相关属性

/**
 *  因为全局只有一个AFHTTPSessionManager实例,所以以下设置方式全局生效
 *  在开发中,如果以下的设置方式不满足项目的需求,就调用此方法获取AFHTTPSessionManager实例进行自定义设置
 *  (注意: 调用此方法时在要导入AFNetworking.h头文件,否则可能会报找不到AFHTTPSessionManager的❌)
 *
 *  @param sessionManager AFHTTPSessionManager的实例
 */
+ (void)tt_setAFHTTPSessionManagerProperty:(void(^)(AFHTTPSessionManager *sessionManager))sessionManager;

/**
 *  设置网络请求参数的格式, 默认为 二进制
 *
 *  @param requestSerializer 请求参数格式
 */
+ (void)tt_setRequestSerializer:(TTRequestSerializer)requestSerializer;

/**
 *  设置服务器响应数据格式, 默认为 JSON
 *
 *  @param responseSerializer 响应数据格式
 */
+ (void)tt_setResponseSerializer:(TTResponseSerializer)responseSerializer;

/**
 *  设置请求超时时间, 默认 30s
 *
 *  @param time 超时时间
 */
+ (void)tt_setRequestTimeoutInterval:(NSTimeInterval)time;

/**
 *  设置请求头
 */
+ (void)tt_setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 *  是否打开网络状态转圈菊花, 默认 YES
 *
 *  @param isOpen YES - 打开, NO - 关闭
 */
+ (void)tt_openNetworkActivityIndicator:(BOOL)isOpen;

/**
 配置自建证书的Https请求, 参考链接: http://blog.csdn.net/syg90178aw/article/details/52839103
 @param cerPath 自建Https证书的路径
 @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO; 即服务器使用其他可信任机构颁发
 的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName=NO, 主要用于这种情况:客户端请求的是子域名, 而证书上的是另外
 一个域名。因为SSL证书上的域名是独立的,假如证书上注册的域名是www.google.com, 那么mail.google.com是无法验证通过的.
 */
+ (void)tt_setSecurityPolicyWithCerPath:(NSString *)cerPath
                    validatesDomainName:(BOOL)validatesDomainName;

@end
