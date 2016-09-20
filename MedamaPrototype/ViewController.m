//
//  ViewController.m
//  MedamaPrototype
//
//  Created by takuji funao on 2016/01/14.
//  Copyright (c) 2016年 takuji funao. All rights reserved.
//

#import "ViewController.h"
#import <CoreFoundation/CoreFoundation.h>

// スマホの傾き
#import <CoreMotion/CoreMotion.h>

// UDP通信
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>


@interface ViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *ipField;
@property (weak, nonatomic) IBOutlet UITextField *portField;
@property IBOutlet UILabel	*xLabel;
@property IBOutlet UILabel	*yLabel;
@property IBOutlet UILabel	*zLabel;
@property(nonatomic) AVAudioPlayer *audioPlayer;

@property (nonatomic, assign) UIBackgroundTaskIdentifier bgid;

@end

@implementation ViewController{
    CMMotionManager *motionManager;
    double xAngle;
    double yAngle;
    double zAngle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.ipField setDelegate:self];
    [self.portField setDelegate:self];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString* ip = [ud stringForKey:@"ip"];
    int port = [ud integerForKey:@"port"];
    NSString *port_str = [NSString stringWithFormat:@"%d", port];
    
    self.ipField.text = ip;
    self.portField.text = port_str;
    
    motionManager = [[CMMotionManager alloc] init];
    [self setupAccelerometer];
    
    NSError *error = nil;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"game" ofType:@"wav"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if ( error != nil ){
        NSLog(@"Error %@", [error localizedDescription]);
    }
    self.audioPlayer.numberOfLoops = -1;
    [self.audioPlayer setDelegate:self];
    [self.audioPlayer play];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(willResignActive:)
                                               name:UIApplicationWillResignActiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connectUnity:(id)sender {
    NSLog(@"connect");
    
    int port = [self.portField.text intValue];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:self.ipField.text forKey:@"ip"];
    [ud setInteger:port forKey:@"port"];
    [ud synchronize];
    
    [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(sendDeviseAngle) userInfo:nil repeats:YES];
    
}

- (void)sendDeviseAngle{
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString* ip = [ud stringForKey:@"ip"];
    int port = [ud integerForKey:@"port"];
    char* ip_char = (char *) [ip UTF8String];
    
    if(ip && port){
        CFSocketRef socket = CFSocketCreate(NULL, PF_INET, SOCK_DGRAM, IPPROTO_UDP, kCFSocketNoCallBack, NULL, NULL);
        
        if (socket == NULL) {
            return;
        }else{
            struct sockaddr_in addr;
            addr.sin_len = sizeof(struct sockaddr_in);
            addr.sin_family = AF_INET;
            addr.sin_addr.s_addr = inet_addr(ip_char);
            addr.sin_port = htons(port);
            CFDataRef address = CFDataCreate(NULL, (UInt8*)&addr, sizeof(struct sockaddr_in));
            
            NSString* xAngleStr = [NSString stringWithFormat : @"%f\t%f\t%f", xAngle, yAngle, zAngle];
            char* xAngleChar = (char *) [xAngleStr UTF8String];
            CFDataRef xData = CFDataCreate(NULL, (UInt8*)xAngleChar, strlen(xAngleChar));
            
            NSLog(@"socket: %@", socket);
            NSLog(@"address: %@", address);
            NSLog(@"xData: %@", xData);
            NSLog(@"\n\n");
            
            CFSocketSendData(socket, address, xData, 3);
            CFRelease(address);
            CFRelease(xData);
        }
        
        CFSocketInvalidate(socket);
        CFRelease(socket);
        
    }
    
}

- (void)setupAccelerometer{
    
    if (motionManager.deviceMotionAvailable) {
        
        
        // 向きの更新通知を開始する
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                                withHandler:^(CMDeviceMotion *motion, NSError *error){
             
             xAngle = motion.attitude.roll * 180 / M_PI + 90;
             yAngle = motion.attitude.yaw * 180 / M_PI * -1;
             zAngle = motion.attitude.pitch * 180 / M_PI * -1;
             
             
             // 画面に表示
             self.xLabel.text = [NSString stringWithFormat:@"x: %0.4f", xAngle];
             self.yLabel.text = [NSString stringWithFormat:@"y: %0.4f", yAngle];
             self.zLabel.text = [NSString stringWithFormat:@"z: %0.4f", zAngle];
             
         }];
    }
    
   
}

- (void)willResignActive:(NSNotification *)notification{
    
    UIApplication *app = UIApplication.sharedApplication;
    self.bgid = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:self.bgid];
        self.bgid = UIBackgroundTaskInvalid;
    }];
}

- (void)didBecomeActive:(NSNotification *)notification{
    
    [UIApplication.sharedApplication endBackgroundTask:self.bgid];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}

@end
