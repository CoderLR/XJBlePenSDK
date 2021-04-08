//
//  DrawView.h
//  XJBleSDKDemo
//
//  Created by apple on 2020/11/19.
//  Copyright © 2020 CoderYS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+Extension.h"
#import <zxybpensdk/ZXYBSdkObject.h>

@interface DrawView : UIView

@property (nonatomic,assign)CGFloat lineWidth;
@property (nonatomic,strong)UIColor *lineColor;

@property (nonatomic, strong) XYDataPacket *packet;

// 清屏
- (void)cleanScreen;

@end

