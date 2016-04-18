//
//  ViewController.m
//  LCHTwilioClientDemo
//
//  Created by apple on 16/4/18.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "ViewController.h"
#import <Masonry.h>
#import <AFNetworking.h>
#import <TCDevice.h>
#import <TCConnection.h>

@interface ViewController ()
<TCDeviceDelegate, TCConnectionDelegate>

#pragma 控件
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UITextView *phoneNumTextView;
@property (nonatomic, strong) UIButton *dialButton;
@property (nonatomic, strong) UIButton *hangUpButton;

#pragma Twilio对象
@property (nonatomic, strong) TCDevice *device;
@property (nonatomic, strong) TCConnection *connection;

#pragma AFNetworking对象
@property (nonatomic, strong) AFHTTPSessionManager *httpSessionManager;

- (void)configMasonry;
- (void)setUpTwilioClient;

- (void)handleDialButton:(UIButton *)sender;
- (void)handleHangUpButton:(UIButton *)sender;

- (void)showAlertActionWithMessage:(NSString *)message;

- (void)showAlertActionToDesideHangUp;
@end

#define WeakSelf(weakSelf) __weak typeof(self) weakSelf = self
#define LogFuncName NSLog(@"%s", __func__)

static CGFloat const kLabelWidth = 150.f;
static CGFloat const kLabelHeight = 40.f;
static CGFloat const kTextViewWidth = 180.f;
static CGFloat const kTextViewHeight = 40.f;
static CGFloat const kButtonWidth = 150.f;
static CGFloat const kButtonHeight = 45.f;
static CGFloat const kPadding = 20.f;
//static NSString *const kServerTokenURL = @"http://adadmin-dev.hadobi.com/hmtwilio/token?client=Jack&allowOutgoing=true";
static NSString *const kServerTokenURL = @"http://confcallserver.herokuapp.com/token?client=Jack&allowOutgoing=true";

@implementation ViewController

#pragma 懒加载

- (UILabel *)label{
    
    if(_label){
        return _label;
    }
    _label = [[UILabel alloc] init];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.text = @"请输入手机号";
    return _label;
}

- (UITextView *)phoneNumTextView{
    
    if(_phoneNumTextView){
        return _phoneNumTextView;
    }
    _phoneNumTextView = [[UITextView alloc] init];
    _phoneNumTextView.textAlignment = NSTextAlignmentCenter;
    _phoneNumTextView.font = [UIFont systemFontOfSize:25];
    _phoneNumTextView.layer.borderColor = [UIColor blackColor].CGColor;
    _phoneNumTextView.layer.borderWidth = 2.f;
    _phoneNumTextView.layer.cornerRadius = 4.f;
    _phoneNumTextView.layer.masksToBounds = YES;
    return _phoneNumTextView;
}

- (UIButton *)dialButton{
    
    if(_dialButton){
        return _dialButton;
    }
    _dialButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _dialButton.layer.cornerRadius = 5.f;
    _dialButton.layer.masksToBounds = YES;
    _dialButton.backgroundColor = [UIColor greenColor];
    [_dialButton setTitle:@"呼叫" forState:UIControlStateNormal];
    [_dialButton addTarget:self action:@selector(handleDialButton:) forControlEvents:UIControlEventTouchUpInside];
    return _dialButton;
}

- (UIButton *)hangUpButton{
    
    if(_hangUpButton){
        return _hangUpButton;
    }
    _hangUpButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _hangUpButton.layer.cornerRadius = 5.f;
    _hangUpButton.layer.masksToBounds = YES;
    _hangUpButton.backgroundColor = [UIColor redColor];
    [_hangUpButton setTitle:@"挂断" forState:UIControlStateNormal];
    [_hangUpButton addTarget:self action:@selector(handleHangUpButton:) forControlEvents:UIControlEventTouchUpInside];
    return _hangUpButton;
}

- (AFHTTPSessionManager *)httpSessionManager{
    
    if(_httpSessionManager){
        return _httpSessionManager;
    }
    _httpSessionManager = [AFHTTPSessionManager manager];
    _httpSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    return _httpSessionManager;
}

#pragma ViewController的生命周期

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.label];
    [self.view addSubview:self.phoneNumTextView];
    [self.view addSubview:self.dialButton];
    [self.view addSubview:self.hangUpButton];
    [self setUpTwilioClient];
}

- (void)viewDidAppear:(BOOL)animated{
    
    [self configMasonry];
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma 内部方法

/**
 *  viewDidAppear之后调用，用于调整约束
 */
- (void)configMasonry{
    WeakSelf(weakSelf);
    
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(weakSelf.view);
        make.width.mas_equalTo(kLabelWidth);
        make.height.mas_equalTo(kLabelHeight);
        make.top.mas_equalTo(weakSelf.view).offset(kPadding * 2);
    }];
    
    [self.phoneNumTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(weakSelf.view);
        make.width.mas_equalTo(kTextViewWidth);
        make.height.mas_equalTo(kTextViewHeight);
        make.top.mas_equalTo(weakSelf.label.mas_bottom).offset(kPadding);
    }];
    
    [self.dialButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(kButtonWidth);
        make.height.mas_equalTo(kButtonHeight);
        make.centerX.mas_equalTo(weakSelf.view).offset(-kButtonWidth * 2 / 3);
        make.top.mas_equalTo(weakSelf.phoneNumTextView.mas_bottom).offset(kPadding);
    }];
    
    [self.hangUpButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(kButtonWidth);
        make.height.mas_equalTo(kButtonHeight);
        make.centerX.mas_equalTo(weakSelf.view).offset(kButtonWidth * 2 / 3);
        make.top.mas_equalTo(weakSelf.phoneNumTextView.mas_bottom).offset(kPadding);
    }];
    
}

/**
 *  从server端获取capabilityToken并建立连接。
 */
- (void)setUpTwilioClient{
    
    [self.httpSessionManager GET:kServerTokenURL parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"连接成功");
        
        if(!responseObject){
            NSLog(@"返回数据为空");
            return ;
        }
        NSString *capabilityToken = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        self.device = [[TCDevice alloc] initWithCapabilityToken:capabilityToken delegate:self];
        self.connection = [self.device connect:nil delegate:nil];
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"连接失败");
        
        [self showAlertActionWithMessage:@"连接失败，无法服务"];
    }];
}


/**
 *  显示用于说明错误信息的AlertController
 *
 *  @param message 错误信息
 */
- (void)showAlertActionWithMessage:(NSString *)message{
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"错误警告" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}


/**
 *  显示用于决定是否挂断当前电话的AlertController
 */
- (void)showAlertActionToDesideHangUp{
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.connection disconnect];
    }];
    
    UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认挂断" message:@"当前正在通话中，确定挂断吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:okAction];
    [alertController addAction:cancleAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
    
}

/**
 *  处理拨号按钮的响应事件
 *
 *  @param sender 拨号按钮：dialButton
 */
- (void)handleDialButton:(UIButton *)sender{
    LogFuncName;
    
    if(self.device.state == TCDeviceStateBusy){
        [self showAlertActionWithMessage:@"正在通话中，请挂断再拨"];
        return;
    }
    if(self.device.state == TCDeviceStateOffline){
        [self showAlertActionWithMessage:@"连接未成功，无法拨通"];
        return;
    }
    
    NSString *inputString = self.phoneNumTextView.text;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9]+$"];
    if([predicate evaluateWithObject:inputString]){
        
        NSDictionary *params = @{@"TO": inputString};
        self.connection = [self.device connect:params delegate:self];
        
    }else{
        [self showAlertActionWithMessage:@"电话号码不合法"];
    }
    
}

/**
 *  处理挂断按钮的响应实践
 *
 *  @param sender 挂断按钮:hangUpButton
 */
- (void)handleHangUpButton:(UIButton *)sender{
    LogFuncName;
    if(self.device.state == TCDeviceStateBusy){
        [self showAlertActionToDesideHangUp];
    }
}

#pragma TCDeviceDelegate协议

- (void)device:(TCDevice *)device didStopListeningForIncomingConnections:(NSError *)error{
    LogFuncName;
    NSLog(@"device did Stop Listening For Incoming Connections With Error: %@", error);
}


- (void)deviceDidStartListeningForIncomingConnections:(TCDevice *)device{
    LogFuncName;
    
}

- (void)device:(TCDevice *)device didReceivePresenceUpdate:(TCPresenceEvent *)presenceEvent{
    LogFuncName;
    
}

- (void)device:(TCDevice *)device didReceiveIncomingConnection:(TCConnection *)connection{
    LogFuncName;
    if(device.state == TCDeviceStateReady){
        [connection accept];
    }else{
        [connection reject];
    }
    
}

#pragma TCConnectionDelegate协议

- (void)connection:(TCConnection *)connection didFailWithError:(NSError *)error{
    LogFuncName;
    NSLog(@"connectiong failWithError: %@", error);
}

- (void)connectionDidStartConnecting:(TCConnection *)connection{
    LogFuncName;
    
}

- (void)connectionDidConnect:(TCConnection *)connection{
    LogFuncName;
    
}

- (void)connectionDidDisconnect:(TCConnection *)connection{
    LogFuncName;
    
}


@end
