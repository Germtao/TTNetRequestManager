//
//  TTNetRequestManager.m
//  TTNetManagerDemo
//
//  Created by TAO on 2017/9/29.
//  Copyright © 2017年 Billow. All rights reserved.
//

#import "TTNetRequestManager.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

#ifdef DEBUG
#define TTLog(...) printf("[%s] %s [第%d行]: %s\n", __TIME__ ,__PRETTY_FUNCTION__ ,__LINE__, [[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
#define TTLog(...)
#endif

#define NSStringFormat(format,...) [NSString stringWithFormat:format,##__VA_ARGS__]

@implementation TTNetRequestManager

static BOOL _isOpenLog;  // 是否已开启日志打印
static NSMutableArray *_allSessionTasks;
static AFHTTPSessionManager *_sessionManager;

#pragma mark - 网络请求
#pragma mark - GET 请求

+ (NSURLSessionTask *)GET:(NSString *)urlStr
               parameters:(id)parameters
                  success:(TTRequestSuccess)requestSuccess
                  failure:(TTRequestFailure)requestFailure {
    
    return [self GET:urlStr parameters:parameters responseCache:nil success:requestSuccess failure:requestFailure];
}

+ (NSURLSessionTask *)GET:(NSString *)urlStr
               parameters:(id)parameters
            responseCache:(TTRequestCache)requestCache
                  success:(TTRequestSuccess)requestSuccess
                  failure:(TTRequestFailure)requestFailure {
    // 读取缓存
    requestCache != nil ? requestCache([TTNetRequestCache tt_getRequestCache:urlStr parameters:parameters]) : nil;
    
    NSURLSessionTask *task = [_sessionManager GET:urlStr parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_isOpenLog) TTLog(@"GET: urlStr = %@, responseObject = %@", urlStr, responseObject);
        
        [[self allSessionTasks] removeObject:task];
        
        requestSuccess ? requestSuccess(responseObject) : nil;
        
        // 对数据进行异步缓存
        requestCache != nil ? [TTNetRequestCache tt_setRequestCache:urlStr parameters:parameters data:responseObject] : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) TTLog(@"GET: urlStr = %@, error = %@", urlStr, error);
        
        [[self allSessionTasks] removeObject:task];
        
        requestFailure ? requestFailure(error) : nil;
        
    }];
    
    // 添加到sessionTasks中
    task ? [[self allSessionTasks] addObject:task] : nil;
    
    return task;
}

#pragma mark - POST 请求

+ (NSURLSessionTask *)POST:(NSString *)urlStr
                parameters:(id)parameters
                   success:(TTRequestSuccess)requestSuccess
                   failure:(TTRequestFailure)requestFailure {
    
    return [self POST:urlStr parameters:parameters responseCache:nil success:requestSuccess failure:requestFailure];
}

+ (NSURLSessionTask *)POST:(NSString *)urlStr
                parameters:(id)parameters
             responseCache:(TTRequestCache)requestCache
                   success:(TTRequestSuccess)requestSuccess
                   failure:(TTRequestFailure)requestFailure {
    
    // 读取缓存
    requestCache != nil ? requestCache([TTNetRequestCache tt_getRequestCache:urlStr parameters:parameters]) : nil;
    
    NSURLSessionTask *task = [_sessionManager POST:urlStr parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_isOpenLog) TTLog(@"POST: urlStr = %@, responseObject = %@", urlStr, responseObject);
        
        [[self allSessionTasks] removeObject:task];
        
        requestSuccess ? requestSuccess(responseObject) : nil;
        
        // 对数据进行异步缓存
        requestCache != nil ? [TTNetRequestCache tt_setRequestCache:urlStr parameters:parameters data:responseObject] : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) TTLog(@"POST: urlStr = %@, error = %@", urlStr, error);
        
        [[self allSessionTasks] removeObject:task];
        
        requestFailure ? requestFailure(error) : nil;
    }];
    
    // 添加到 sessionTasks 中
    task ? [[self allSessionTasks] addObject:task] : nil;
    
    return task;
}

#pragma mark - Upload (File & Images)

+ (NSURLSessionTask *)tt_uploadFileWithURL:(NSString *)urlStr
                                parameters:(id)parameters
                                  fileName:(NSString *)fileName
                                  filePath:(NSString *)filePath
                                  progress:(TTRequestPropress)requestProgress
                                   success:(TTRequestSuccess)requestSuccess
                                   failure:(TTRequestFailure)requestFailure {
    
    NSURLSessionTask *task = [_sessionManager POST:urlStr parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:fileName error:&error];
        (requestFailure && error) ? requestFailure(error) : nil;
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        // 上传进度
        dispatch_async(dispatch_get_main_queue(), ^{
            requestProgress ? requestProgress(uploadProgress) : nil;
        });
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_isOpenLog) TTLog(@"UploadFile: %@, responseObject = %@", urlStr, responseObject);
        
        [[self allSessionTasks] removeObject:task];
        
        requestSuccess ? requestSuccess(responseObject) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) TTLog(@"UploadFile: %@, error = %@", urlStr, error);
        
        [[self allSessionTasks] removeObject:task];
        
        requestFailure ? requestFailure(error) : nil;
        
    }];
    
    // 添加到 sessionTasks 数组中
    task ? [[self allSessionTasks] addObject:task] : nil;
    
    return task;
}

+ (NSURLSessionTask *)tt_uploadImagesWithURL:(NSString *)urlStr
                                  parameters:(id)parameters
                                   imageName:(NSString *)imageName
                                      images:(NSArray<UIImage *> *)images
                                   fileNames:(NSArray<NSString *> *)fileNames
                                  imageScale:(CGFloat)imageScale
                                   imageType:(NSString *)imageType
                                    progress:(TTRequestPropress)requestProgress
                                     success:(TTRequestSuccess)requestSuccess
                                     failure:(TTRequestFailure)requestFailure {
    
    NSURLSessionTask *task = [_sessionManager POST:urlStr parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (NSInteger i = 0; i < images.count; i++) {
            
            // 图片经过等比压缩得到的二进制文件
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ? :1.f);
            
            // 默认图片的文件名, 若fileNames为nil就使用
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *imageFileName = NSStringFormat(@"%@%ld.%@",str, i, imageType ? : @"jpg");
            
            [formData appendPartWithFileData:imageData
                                        name:imageName
                                    fileName:fileNames ? NSStringFormat(@"%@.%@", fileNames[i], imageType ? : @".jpg") : imageFileName
                                    mimeType:NSStringFormat(@"image/%@", imageType ? : @"jpg")];
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        // 上传进度
        dispatch_async(dispatch_get_main_queue(), ^{
            requestProgress ? requestProgress(uploadProgress) : nil;
        });
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_isOpenLog) TTLog(@"UploadImage: %@, responseObject = %@", urlStr, responseObject);
        
        [[self allSessionTasks] removeObject:task];
        
        requestSuccess ? requestSuccess(responseObject) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) TTLog(@"UploadImage: %@, error = %@", urlStr, error);
        
        [[self allSessionTasks] removeObject:task];
        
        requestFailure ? requestFailure(error) : nil;
        
    }];
    
    // 添加到 sessionTasks 数组中
    task ? [[self allSessionTasks] addObject:task] : nil;
    
    return task;
}

#pragma mark - Download

+ (NSURLSessionTask *)tt_downloadWithURL:(NSString *)urlStr
                                 fileDir:(NSString *)fileDir
                                progress:(TTRequestPropress)requestProgress
                                 success:(TTRequestSuccess)requestSuccess
                                 failure:(TTRequestFailure)requestFailure {
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    
    __block NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        // 下载进度
        dispatch_async(dispatch_get_main_queue(), ^{
            requestProgress ? requestProgress(downloadProgress) : nil;
        });
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        //拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        //打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //创建Download目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        //拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        //返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        [[self allSessionTasks] removeObject:downloadTask];
        
        if (requestFailure && error) {requestFailure(error); return ;}
        
        requestSuccess ? requestSuccess(filePath.absoluteString) : nil;
        
    }];
    
    // 开始下载
    [downloadTask resume];
    
    // 添加到 sessionTasks 数组中
    downloadTask ? [[self allSessionTasks] addObject:downloadTask] : nil;
    
    return downloadTask;
}

#pragma mark - 取消网络请求

+ (void)tt_cancelAllRequest {
    // 锁操作
    @synchronized(self) {
        [[self allSessionTasks] enumerateObjectsUsingBlock:^(NSURLSessionTask *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTasks] removeAllObjects];
    }
}

+ (void)tt_cancelRequestWithURL:(NSString *)urlStr {
    
    if (!urlStr) return;
    
    @synchronized(self) {
        [[self allSessionTasks] enumerateObjectsUsingBlock:^(NSURLSessionTask *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:urlStr]) {
                [task cancel];
                [[self allSessionTasks] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

#pragma mark - 开始监听网络状态

+ (void)tt_networkStatusWithBlock:(TTNetworkStatus)networkStatus {
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown: {
                networkStatus ? networkStatus(TTNetworkStatusType_UnKnow) : nil;
                if (_isOpenLog) TTLog(@"未知网络");
                break;
            }
            case AFNetworkReachabilityStatusNotReachable: {
                networkStatus ? networkStatus(TTNetworkStatusType_NotNet) : nil;
                if (_isOpenLog) TTLog(@"无网络");
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWWAN: {
                networkStatus ? networkStatus(TTNetworkStatusType_WWAN) : nil;
                if (_isOpenLog) TTLog(@"手机网络");
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWiFi: {
                networkStatus ? networkStatus(TTNetworkStatusType_WiFi) : nil;
                if (_isOpenLog) TTLog(@"WiFi网络");
                break;
            }
        }
    }];
}

+ (BOOL)tt_isHasNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

+ (BOOL)tt_isHasWWAN {
    return [AFNetworkReachabilityManager sharedManager].isReachableViaWWAN;
}

+ (BOOL)tt_isHasWiFi {
    return [AFNetworkReachabilityManager sharedManager].isReachableViaWiFi;
}

+ (void)tt_openLog {
    _isOpenLog = YES;
}

+ (void)tt_closeLog {
    _isOpenLog = NO;
}

#pragma mark - Lazy Load

+ (NSMutableArray *)allSessionTasks {
    if (!_allSessionTasks) {
        _allSessionTasks  = [NSMutableArray array];
    }
    return _allSessionTasks;
}

#pragma mark - 初始化AFHTTPSessionManager相关属性

/**
 开始监测网络状态
 */
+ (void)load {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}
/**
 *  所有的HTTP请求共享一个AFHTTPSessionManager
 *  原理参考地址:http://www.jianshu.com/p/5969bbb4af9f
 */
+ (void)initialize {
    _sessionManager = [AFHTTPSessionManager manager];
    _sessionManager.requestSerializer.timeoutInterval = 30.f;
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    // 打开状态栏的等待菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}

#pragma mark - 重置AFHTTPSessionManager相关属性

+ (void)tt_setAFHTTPSessionManagerProperty:(void (^)(AFHTTPSessionManager *))sessionManager {
    sessionManager ? sessionManager(_sessionManager) : nil;
}

+ (void)tt_setRequestSerializer:(TTRequestSerializer)requestSerializer {
    _sessionManager.requestSerializer = (requestSerializer == TTRequestSerializer_HTTP) ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
}

+ (void)tt_setResponseSerializer:(TTResponseSerializer)responseSerializer {
    _sessionManager.responseSerializer = (responseSerializer == TTResponseSerializer_HTTP) ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
}

+ (void)tt_setRequestTimeoutInterval:(NSTimeInterval)time {
    _sessionManager.requestSerializer.timeoutInterval = time;
}

+ (void)tt_setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [_sessionManager.requestSerializer setValue:value forKey:field];
}

+ (void)tt_openNetworkActivityIndicator:(BOOL)isOpen {
    [AFNetworkActivityIndicatorManager sharedManager].enabled = isOpen;
}

+ (void)tt_setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName {
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 如果需要验证自建证书(无效证书)，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认为YES;
    securityPolicy.validatesDomainName = validatesDomainName;
    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    
    [_sessionManager setSecurityPolicy:securityPolicy];
}

@end

#pragma mark - NSDictionary,NSArray的分类
/*
 ************************************************************************************
 *新建NSDictionary与NSArray的分类, 控制台打印json数据中的中文
 ************************************************************************************
 */

#ifdef DEBUG
@implementation NSArray (PP)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"(\n"];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [strM appendFormat:@"\t%@,\n", obj];
    }];
    [strM appendString:@")"];
    
    return strM;
}

@end

@implementation NSDictionary (PP)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"{\n"];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [strM appendFormat:@"\t%@ = %@;\n", key, obj];
    }];
    
    [strM appendString:@"}\n"];
    
    return strM;
}
@end
#endif
