//
//  TTNetRequestCache.h
//  TTNetManagerDemo
//
//  Created by TAO on 2017/9/28.
//  Copyright © 2017年 Billow. All rights reserved.
//
/**
 *  网络数据缓存类
 */

#import <Foundation/Foundation.h>

#define TTExpired(instead) NS_DEPRECATED(2_0, 2_0, 2_0, instead)  // 过期提醒

@interface TTNetRequestCache : NSObject

/**
 *  异步缓存网络数据, 根据请求的 URL、parameters
 *  做 key 存储数据, 这样就能缓存多级页面的数据
 *
 *  @param urlStr     请求的地址
 *  @param parameters 请求的参数
 *  @param reqData    请求返回的数据
 */
+ (void)tt_setRequestCache:(NSString *)urlStr
                parameters:(id)parameters
                      data:(id)reqData;

/**
 *  根据请求的 URL、parameters 同步取出缓存数据
 *
 *  @param urlStr     请求的地址
 *  @param parameters 请求的参数
 *
 *  @return 缓存的请求数据
 */
+ (id)tt_getRequestCache:(NSString *)urlStr
              parameters:(id)parameters;

/**
 *  获取网络缓存数据的总大小 bytes
 */
+ (NSInteger)tt_getAllRequestCacheSize;

/**
 *  删除所有网络缓存数据
 */
+ (void)tt_removeAllRequestCache;

@end
