//
//  TTNetRequest.h
//  TTNetManagerDemo
//
//  Created by TAO on 2017/9/29.
//  Copyright © 2017年 Billow. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 *  以下Block的参数你根据自己项目中的需求来指定, 这里仅仅是一个演示的例子🌰
 */

typedef void(^TTLoginSuccess)(id response);
typedef void(^TTLoginFailure)(NSError *error);

@interface TTNetRequest : NSObject

#pragma mark - Login/out

+ (NSURLSessionTask *)tt_getLoginWithParameters:(id)parameters
                                        success:(TTLoginSuccess)loginSuccess
                                        failure:(TTLoginFailure)loginFailure;

+ (NSURLSessionTask *)tt_getLogoutWithParameters:(id)parameters
                                         success:(TTLoginSuccess)logoutSuccess
                                         failure:(TTLoginFailure)logoutFailure;

@end
