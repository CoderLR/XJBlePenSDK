//
//  MBProgressHUD+KJExtensuon.m
//  CustomCamera
//
//  Created by apple on 2017/6/20.
//  Copyright © 2017年 jiankangzhan. All rights reserved.
//

#import "MBProgressHUD+KJExtension.h"

@implementation MBProgressHUD (KJExtension)

+ (void)showHUD
{
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:keyWindow animated:YES];
    hud.contentColor = [UIColor whiteColor];
    hud.bezelView.backgroundColor = [UIColor blackColor];
//    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
//    hud.bezelView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    hud.margin = 12;
    hud.square = YES;
    hud.animationType = MBProgressHUDAnimationZoomOut;
    //    hud.offset = CGPointMake(0.f, 0.f);
    hud.label.text = @"加载中...";
    hud.label.font = [UIFont systemFontOfSize:14.f];
}

+ (void)showHUDWithText:(NSString *)msg
{
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:keyWindow animated:YES];
    hud.contentColor = [UIColor whiteColor];
    hud.bezelView.backgroundColor = [UIColor blackColor];
    hud.margin = 12;
    hud.square = YES;
    hud.animationType = MBProgressHUDAnimationZoomOut;
    //    hud.offset = CGPointMake(0.f, 0.f);
    hud.label.text = msg;
    hud.label.font = [UIFont systemFontOfSize:14.f];
}

+ (void)showCustonHUDWithText:(NSString *)msg {
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:keyWindow animated:YES];
    hud.contentColor = [UIColor whiteColor];
    hud.bezelView.backgroundColor = [UIColor blackColor];
    
    hud.mode = MBProgressHUDModeCustomView;
    
    UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    hud.customView = [[UIImageView alloc] initWithImage:image];
    
    hud.margin = 12;
    hud.square = YES;
    
    hud.label.text = msg;
    hud.label.font = [UIFont systemFontOfSize:14.f];
    
    [hud hideAnimated:YES afterDelay:2.5];
}


+ (void)showMessageWithText:(NSString *)msg
{
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:keyWindow animated:YES];
    
    hud.bezelView.backgroundColor = [UIColor blackColor];
    
    hud.animationType = MBProgressHUDAnimationZoomOut;
    
    hud.margin = 12;

    hud.mode = MBProgressHUDModeText;
    hud.label.text = msg;
    hud.label.font = [UIFont systemFontOfSize:14.f];
    hud.label.textColor = [UIColor whiteColor];

    hud.offset = CGPointMake(0.f, 0.f);
    [hud hideAnimated:YES afterDelay:2.5];
}


+ (void)hideHUD
{
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [MBProgressHUD hideHUDForView:keyWindow animated:YES];
}

@end
