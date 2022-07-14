//
//  ZXYBSdk.h
//  KJBleSDKDemo
//
//  Created by yangshuai on 2020/11/18.
//  Copyright © 2020 CoderYS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ZXYBSdkObject.h"

#pragma mark - ZXYBSdkDelegate
@protocol ZXYBSdkDelegate <NSObject>
@optional

/// 蓝牙数据回调
/// @param o 数据对象
- (void)onXYPackDataProc:(XYDataPacket *)o;

/// 慧板按钮点击状态
/// @param btn_index 101~112 保存~上页
/// @param isDown 按下或抬起
- (void)onKeySoftKeyCallBack:(int)btn_index isDown:(BOOL)isDown;

/// 返回设备的信息参数
/// @param info 返回蓝牙信息对象
- (void)onBackBoardInfo:(XYBoardInfo *)info;

/// 慧板按钮点击
/// @param btn_index 101~112 保存~上页
- (void)onBtnIndexCallBack:(int)btn_index;

/// 蓝牙连接状态
/// @param status 连接状态
- (void)onXYEnvNotifyProc:(ZXYBleConnectStatus)status;

/// 蓝牙扫描回调
/// @param peripherals [CBPeripheral]
- (void)onScanDevice:(NSArray *)peripherals;

@end

#pragma mark - ZXYBSdk
@interface ZXYBSdk : NSObject

/// 代理用于数据回调
@property (nonatomic, weak) id<ZXYBSdkDelegate> delegate;

/// 单例对象
+ (ZXYBSdk *)instance;

/// 释放单例对象
- (void)destoryInstance;

/// API版本
+ (NSString *)getApiVersion;

/// 是否自动连接
/// @param isAutoConnect 自动连接
- (void)XYInit:(BOOL)isAutoConnect;

/// 设置超时时间
/// @param timeInterval 超时时间
- (void)XYSetTimeOutInterval:(NSInteger)timeInterval;

/// 设置工作区域
/// @param size App坐标
- (void)XYSetWorkRegion:(CGSize)size;

/// 设置XY坐标的横纵向
/// @param orient 默认为 1 横向 0：纵向
- (void)setOrientation:(int)orient;

/// 解析蓝牙数据
/// @param drawData 蓝牙接收到的二进制数据
- (void)getBoardData:(NSData *)drawData;

/// 开始扫描蓝牙
- (void)scanBluetool;

/// 停止扫描
- (void)stopScan;

/// 蓝牙连接状态
- (BOOL)isConnected;

/// 手机蓝牙是否打开
- (BOOL)isBleOpen;

/// 连接设备
/// @param peripheral 外设对象
- (void)connect:(CBPeripheral *)peripheral;

/// 断开连接（用户主动）
/// @param peripheral 外设对象
- (void)disconnect:(CBPeripheral *)peripheral;

/// 向蓝牙发送数据
- (void)sendData:(NSData *)data;

@end

