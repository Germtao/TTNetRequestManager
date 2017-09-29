//
//  ViewController.m
//  TTNetManagerDemo
//
//  Created by TAO on 2017/9/28.
//  Copyright © 2017年 Billow. All rights reserved.
//

#import "ViewController.h"
#import "TTNetRequestManager.h"
#import "TTNetRequestCache.h"
#import "TTNetRequest.h"

#ifdef DEBUG
#define TTLog(...) printf("[%s] %s [第%d行]: %s\n", __TIME__ ,__PRETTY_FUNCTION__ ,__LINE__, [[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
#define TTLog(...)
#endif

#define SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height

static NSString *const dataUrl = @"http://api.budejie.com/api/api_open.php";
static NSString *const downloadUrl = @"http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4";

@interface ViewController ()

@property (nonatomic, weak) UITextView *networkData;
@property (nonatomic, weak) UITextView *cacheData;
@property (nonatomic, weak) UILabel *cacheStatus;
@property (nonatomic, weak) UISwitch *cacheSwitch;
@property (nonatomic, weak) UIProgressView *progressView;
@property (nonatomic, weak) UIButton *downloadBtn;

/**
 *  是否开启缓存
 */
@property (nonatomic, assign, getter=isCache) BOOL cache;
/**
 *  是否开始下载
 */
@property (nonatomic, assign, getter=isDownload) BOOL download;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initUI];
}

#pragma mark - 网络请求

- (void)configureNetwork {
    /**
     设置网络请求参数的格式:默认为二进制格式
     
     设置方式 : [TTNetRequestManager tt_setRequestSerializer:TTRequestSerializer_HTTP];
     */
    
    /**
     设置服务器响应数据格式:默认为JSON格式
     PPResponseSerializerJSON(JSON格式),
     PPResponseSerializerHTTP(二进制格式)
     
     设置方式 : [TTNetRequestManager tt_setResponseSerializer:TTResponseSerializer_JSON];
     */
    
    /**
     设置请求头 : [TTNetRequestManager tt_setValue:@"value" forHTTPHeaderField:@"header"];
     */
    
    // 开启日志打印
    [TTNetRequestManager tt_openLog];
    
    // 获取网络缓存大小
    TTLog(@"网络缓存大小cache = %fKB", [TTNetRequestCache tt_getAllRequestCacheSize]/1024.f);
    
    // 清理缓存 [PPNetworkCache removeAllHttpCache];
    
    // 实时监测网络状态
    [self monitorNetworkStatus];
    
    /*
     * 一次性获取当前网络状态
     这里延时0.1s再执行是因为程序刚刚启动,可能相关的网络服务还没有初始化完成(也有可能是AFN的BUG),
     导致此demo检测的网络状态不正确,这仅仅只是为了演示demo的功能性, 在实际使用中可直接使用一次性网络判断,不用延时
     */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self getCurrentNetworkStatus];
    });
    
    [self TTHTTPRequestLayerDemo];
}

/**
 
 通过封装好的网络层进行请求配 , 我目前的项目是这样做的,在工程中的 PPHTTPRequestLayer 文件夹可以看到
 当然,不同的项目可以有不同的做法,没有最好的做法,只有最合适的做法,
 这仅仅是我抛砖引玉, 希望大家能各显神通.
 */
- (void)TTHTTPRequestLayerDemo
{
    // 登陆
    [TTNetRequest tt_getLoginWithParameters:@"参数" success:^(id response) {
        
    } failure:^(NSError *error) {
        
    }];
    
    // 退出
    [TTNetRequest tt_getLogoutWithParameters:@"参数" success:^(id response) {
        
    } failure:^(NSError *error) {
        
    }];
}

#pragma  mark - 获取数据请求示例 GET请求自动缓存与无缓存
#pragma  mark - 这里的请求只是一个演示, 在真实的项目中建议不要这样做, 具体做法可以参照PPHTTPRequestLayer文件夹的例子
- (void)getData:(BOOL)isOn url:(NSString *)url
{
    
    NSDictionary *para = @{ @"a":@"list", @"c":@"data",@"client":@"iphone",@"page":@"0",@"per":@"10", @"type":@"29"};
    // 自动缓存
    if(isOn)
    {
        self.cacheStatus.text = @"缓存打开";
        self.cacheSwitch.on = YES;
        
        [TTNetRequestManager GET:url parameters:para responseCache:^(id responseCache) {
            // 1.先加载缓存数据
            self.cacheData.text = [self jsonToString:responseCache];
        } success:^(id responseObject) {
            // 2.再请求网络数据
            self.networkData.text = [self jsonToString:responseObject];
        } failure:^(NSError *error) {
            
        }];
        
    }
    // 无缓存
    else
    {
        self.cacheStatus.text = @"缓存关闭";
        self.cacheSwitch.on = NO;
        self.cacheData.text = @"";
        
        [TTNetRequestManager GET:url parameters:para success:^(id responseObject) {
            self.networkData.text = [self jsonToString:responseObject];
        } failure:^(NSError *error) {
            
        }];
        
    }
    
}
#pragma mark - 实时监测网络状态
- (void)monitorNetworkStatus
{
    // 网络状态改变一次, networkStatusWithBlock就会响应一次
    [TTNetRequestManager tt_networkStatusWithBlock:^(TTNetworkStatusType networkStatus) {
        
        switch (networkStatus) {
                // 未知网络
            case TTNetworkStatusType_UnKnow:
                // 无网络
            case TTNetworkStatusType_NotNet:
                self.networkData.text = @"没有网络";
                [self getData:YES url:dataUrl];
                TTLog(@"无网络,加载缓存数据");
                break;
                // 手机网络
            case TTNetworkStatusType_WWAN:
                // 无线网络
            case TTNetworkStatusType_WiFi:
                [self getData:[[NSUserDefaults standardUserDefaults] boolForKey:@"isOn"] url:dataUrl];
                TTLog(@"有网络,请求网络数据");
                break;
        }
        
    }];
    
}

#pragma mark - 一次性获取当前最新网络状态
- (void)getCurrentNetworkStatus
{
    if (IsHasNet) {
        TTLog(@"有网络");
        if (IsHasWWAN) {
            TTLog(@"手机网络");
        }else if (IsHasWiFi){
            TTLog(@"WiFi网络");
        }
    } else {
        TTLog(@"无网络");
    }
    // 或
    //    if ([PPNetworkHelper isNetwork]) {
    //        PPLog(@"有网络");
    //        if ([PPNetworkHelper isWWANNetwork]) {
    //            PPLog(@"手机网络");
    //        }else if ([PPNetworkHelper isWiFiNetwork]){
    //            PPLog(@"WiFi网络");
    //        }
    //    } else {
    //        PPLog(@"无网络");
    //    }
}

#pragma mark - Private Method

/**
 *  json转字符串
 */
- (NSString *)jsonToString:(NSDictionary *)dic
{
    if(!dic){
        return nil;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark - Init UI

- (void)initUI {
    [self initNetworkData];
    [self initCacheData];
    [self initCacheLabelAndSwitch];
    [self initProgressViewAndDownloadButton];
}

- (void)initNetworkData {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 20, SCREEN_WIDTH - 10, 21)];
    label.text = @"网络数据";
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(5, 45, SCREEN_WIDTH - 10, 150)];
    textView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:textView];
    self.networkData = textView;
}

- (void)initCacheData {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, CGRectGetMaxY(_networkData.frame), SCREEN_WIDTH - 10, 21)];
    label.text = @"缓存数据";
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(5, CGRectGetMaxY(label.frame) + 4, SCREEN_WIDTH - 10, 150)];
    textView.backgroundColor = [UIColor cyanColor];
    [self.view addSubview:textView];
    self.cacheData = textView;
}

- (void)initCacheLabelAndSwitch {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, CGRectGetMaxY(_cacheData.frame) + 40, 100, 21)];
    label.text = @"开启缓存";
    [self.view addSubview:label];
    self.cacheStatus = label;
    
    UISwitch *cacheSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_cacheStatus.frame) + 10, CGRectGetMidY(_cacheStatus.frame), 50, 30)];
    cacheSwitch.tintColor = [UIColor greenColor];
    cacheSwitch.onTintColor = [UIColor greenColor];
    cacheSwitch.thumbTintColor = [UIColor blueColor];
    [cacheSwitch addTarget:self action:@selector(cacheSwitchIsOn:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:cacheSwitch];
    self.cacheSwitch = cacheSwitch;
}

- (void)initProgressViewAndDownloadButton {
    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 150 - 10, CGRectGetMidY(_cacheSwitch.frame), 150, 20)];
    progressView.progressTintColor = [UIColor blueColor];
    progressView.trackTintColor = [UIColor darkGrayColor];
    [self.view addSubview:progressView];
    self.progressView = progressView;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(SCREEN_WIDTH - 100 - 10, CGRectGetMaxY(_progressView.frame) + 20, 100, 30);
    [button setTitle:@"开始下载" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor redColor]];
    [button addTarget:self action:@selector(downloadBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    self.downloadBtn = button;
}

#pragma mark - Target Event

- (void)downloadBtnPressed:(UIButton *)sender {
    static NSURLSessionTask *task = nil;
    //开始下载
    if(!self.isDownload)
    {
        self.download = YES;
        [self.downloadBtn setTitle:@"取消下载" forState:UIControlStateNormal];
        
        task = [TTNetRequestManager tt_downloadWithURL:downloadUrl fileDir:@"Download" progress:^(NSProgress *progress) {
            
            CGFloat stauts = 100.f * progress.completedUnitCount/progress.totalUnitCount;
            self.progressView.progress = stauts/100.f;
            
            TTLog(@"下载进度 :%.2f%%,,%@",stauts,[NSThread currentThread]);
        } success:^(NSString *filePath) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载完成!"
                                                                message:[NSString stringWithFormat:@"文件路径:%@",filePath]
                                                               delegate:nil
                                                      cancelButtonTitle:@"确定"
                                                      otherButtonTitles:nil];
            [alertView show];
            [self.downloadBtn setTitle:@"重新下载" forState:UIControlStateNormal];
            TTLog(@"filePath = %@",filePath);
            
        } failure:^(NSError *error) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载失败"
                                                                message:[NSString stringWithFormat:@"%@",error]
                                                               delegate:nil
                                                      cancelButtonTitle:@"确定"
                                                      otherButtonTitles:nil];
            [alertView show];
            TTLog(@"error = %@",error);
        }];
        
    }
    //暂停下载
    else {
        self.download = NO;
        [task suspend];
        self.progressView.progress = 0;
        [self.downloadBtn setTitle:@"开始下载" forState:UIControlStateNormal];
    }
}

- (void)cacheSwitchIsOn:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"isOn"];
    
    [self getData:sender.isOn url:dataUrl];
}

@end
