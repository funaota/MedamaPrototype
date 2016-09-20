//
//  ViewController.h
//  MedamaPrototype
//
//  Created by takuji funao on 2016/01/14.
//  Copyright (c) 2016年 takuji funao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<AVAudioPlayerDelegate>

- (void)sendDeviseAngle;

@end

