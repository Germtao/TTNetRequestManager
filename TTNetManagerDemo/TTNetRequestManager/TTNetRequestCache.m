//
//  TTNetRequestCache.m
//  TTNetManagerDemo
//
//  Created by TAO on 2017/9/28.
//  Copyright © 2017年 Billow. All rights reserved.
//

#import "TTNetRequestCache.h"
#import "YYCache.h"

static NSString *const kNetResponseCache = @"NetResponseCache";

@implementation TTNetRequestCache
static YYCache *_dataCache;

+ (void)initialize {
    _dataCache = [YYCache cacheWithName:kNetResponseCache];
}

+ (void)tt_setRequestCache:(NSString *)urlStr parameters:(id)parameters data:(id)reqData {
    NSString *cacheKey = [self cacheKeyWithURL:urlStr parameters:parameters];
    
    // 异步缓存, 不会阻塞主线程
    [_dataCache setObject:reqData forKey:cacheKey withBlock:nil];
}

+ (id)tt_getRequestCache:(NSString *)urlStr parameters:(id)parameters {
    NSString *cacheKey = [self cacheKeyWithURL:urlStr parameters:parameters];
    return [_dataCache objectForKey:cacheKey];
}

+ (NSInteger)tt_getAllRequestCacheSize {
    return [_dataCache.diskCache totalCost];
}

+ (void)tt_removeAllRequestCache {
    [_dataCache.diskCache removeAllObjects];
}

#pragma mark - Private Method

+ (NSString *)cacheKeyWithURL:(NSString *)urlStr parameters:(NSDictionary *)parameters {
    
    if (!parameters || parameters.count == 0) return urlStr;
    
    // 将参数字典转换成字符串
    NSData *dataStr = [NSJSONSerialization dataWithJSONObject:parameters
                                                      options:0 error:nil];
    NSString *paraStr = [[NSString alloc] initWithData:dataStr encoding:NSUTF8StringEncoding];
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@", urlStr, paraStr];
    
    return [NSString stringWithFormat:@"%ld", cacheKey.hash];
}

@end
