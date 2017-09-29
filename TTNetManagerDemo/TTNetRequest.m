//
//  TTNetRequest.m
//  TTNetManagerDemo
//
//  Created by TAO on 2017/9/29.
//  Copyright © 2017年 Billow. All rights reserved.
//

#import "TTNetRequest.h"
#import "TTInterfacedConst.h"
#import "TTNetRequestManager.h"

@implementation TTNetRequest

+ (NSURLSessionTask *)tt_getLoginWithParameters:(id)parameters success:(TTLoginSuccess)loginSuccess failure:(TTLoginFailure)loginFailure {
    // 将请求前缀与请求路径拼接成一个完整的URL
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kApiPrefix, kLogin];
    
    return [self requestWithURL:urlStr parameters:parameters success:loginSuccess failure:loginFailure];
}

+ (NSURLSessionTask *)tt_getLogoutWithParameters:(id)parameters success:(TTLoginSuccess)logoutSuccess failure:(TTLoginFailure)logoutFailure {
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kApiPrefix, kLogout];
    
    return [self requestWithURL:urlStr parameters:parameters success:logoutSuccess failure:logoutFailure];
}

#pragma mark - 请求的公共方法

+ (NSURLSessionTask *)requestWithURL:(NSString *)urlStr parameters:(id)parameters success:(TTLoginSuccess)requestSuccess failure:(TTLoginFailure)requestFailure {
    // 在请求之前你可以统一配置你请求的相关参数 ,设置请求头, 请求参数的格式, 返回数据的格式....这样你就不需要每次请求都要设置一遍相关参数
    
    // 设置请求头
    [TTNetRequestManager tt_setValue:@"9" forHTTPHeaderField:@"fromType"];
    
    // 发起请求
    return [TTNetRequestManager POST:urlStr parameters:parameters success:^(id responseObject) {
        
        // 在这里你可以根据项目自定义其他一些重复操作,比如加载页面时候的等待效果, 提醒弹窗....
        requestSuccess(responseObject);
        
    } failure:^(NSError *error) {
        // 同上
        requestFailure(error);
    }];
}

@end
