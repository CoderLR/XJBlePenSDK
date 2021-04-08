//
//  ZXYBSdkObject.h
//  XJBleSDKDemo
//
//  Created by yangshuai on 2020/11/19.
//  Copyright © 2020 CoderYS. All rights reserved.
//

#import <Foundation/Foundation.h>

/// 蓝牙连接状态
typedef enum : NSUInteger {
    ZXYBleConnectNormal    = 0, // 正常状态
    ZXYBleConnectFail      = 1, // 连接失败
    ZXYBleConnectSuccess   = 2, // 连接成功
    ZXYBleDisconnect       = 3, // 连接中断
    ZXYBleConnectTimeOut   = 4, // 连接超时
    ZXYBleAutoConnectError = 5, // 自动连接超时
    ZXYBleScanTimeOut      = 6  // 扫描超时
} ZXYBleConnectStatus;

#pragma mark - 蓝牙解析数据实体类
@interface XYDataPacket : NSObject

/// 笔的状态 0 悬停 1 按下 2 移动 3 抬起 4 离开
@property (nonatomic, assign) int penStatus;

/// 物理坐标X B5 0~21000
@property (nonatomic, assign) int x;

/// 物理坐标Y B5 0~14800
@property (nonatomic, assign) int y;

/// app绘画区域X 默认 0~768
@property (nonatomic, assign) int tx;

/// app绘画区域Y 默认 0~1080
@property (nonatomic, assign) int ty;

/// 压力值 最大8191
@property (nonatomic, assign) float pressure;

/// dx
@property (nonatomic, assign) float dx;

/// dy
@property (nonatomic, assign) float dy;

/// timestamp
@property (nonatomic, assign) long timestamp;

/// type
@property (nonatomic, assign) int type;

/// n
@property (nonatomic, assign) int n;

/// buttonIndex
@property (nonatomic, assign) int buttonIndex;

@end

#pragma mark - 蓝牙板实体类
@interface XYBoardInfo : NSObject

/// 蓝牙版类型 6
@property (nonatomic, assign) int boardType;

/// 最多物理X 21000
@property (nonatomic, assign) int maxX;

/// 最大物理Y 14800
@property (nonatomic, assign) int maxY;

/// 最大压力值 8191
@property (nonatomic, assign) int pressure;

@end
