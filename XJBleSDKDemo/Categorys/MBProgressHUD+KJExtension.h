//
//  MBProgressHUD+KJExtensuon.h
//  CustomCamera
//
//  Created by apple on 2017/6/20.
//  Copyright © 2017年 jiankangzhan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface MBProgressHUD (KJExtension)

+ (void)showHUD;

+ (void)showHUDWithText:(NSString *)msg;

+ (void)showCustonHUDWithText:(NSString *)msg;

+ (void)showMessageWithText:(NSString *)msg;

+ (void)hideHUD;

@end
