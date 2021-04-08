//
//  XYManager.h
//  XJBleSDKDemo
//
//  Created by yangshuai on 2020/11/18.
//  Copyright © 2020 CoderYS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
@class XYManager;

static NSString * const XYCentralErrorScanTimeOut = @"scan time out";
static NSString * const XYCentralErrorConnectTimeOut = @"connect time out";
static NSString * const XYCentralErrorBluetoothPowerOff = @"bluetooth power off";
static NSString * const XYCentralErrorBluetoothOtherState = @"bluetooth other state";
static NSString * const XYCentralErrorConnectAutoConnectFail = @"auto connect fail";
static NSString * const XYCentralErrorWriteDataLength = @"data length error";

//service = FFF0
//characteristic = FFF1
//characteristic = FFF2

/// 慧板服务特性
static NSString * const ZXY_SERVICE_UUID = @"FFF0";
static NSString * const ZXY_CHARACTERISTIC_UUID_RED = @"FFF1";
static NSString * const ZXY_CHARACTERISTIC_UUID_NOTIFY = @"FFF1";
static NSString * const ZXY_CHARACTERISTIC_UUID_WRITE = @"FFF2";

@protocol XYManagerDelegate <NSObject>

@optional

// 蓝牙状态
- (void)centralManger:(XYManager *)centralManger bluetoothStatus:(NSError *)error;

// 找到 Peripheral，没找到一个都会返回全部 Peripheral 的数组
- (void)centralManger:(XYManager *)centralManger findPeripherals:(NSMutableArray *)peripherals;

// 扫描外设超时 默认扫描30s
- (void)centralManger:(XYManager *)centralManger scanTimeOut:(NSError *)error;

// 连接超时 默认30s
- (void)centralManger:(XYManager *)centralManger connectTimeOut:(NSError *)error;

// 连接失败
- (void)centralManger:(XYManager *)centralManger connectFailure:(NSError *)error;

// 连接成功（仅仅是 Peripheral 连接成功，如果内部的 Service 或者 Characteristic 连接失败，会走失败代理）
- (void)centralManger:(XYManager *)centralManger connectSuccess:(CBPeripheral *)peripheral;

// 断开连接（准备断开就会走这个方法，具体是否真正断开要看苹果底层的实现，如果有其他 app 正连接着，不会断开）
- (void)centralManger:(XYManager *)centralManger disconnectPeripheral:(CBPeripheral *)peripheral;

// 收到 Peripheral 发过来的数据
- (void)centralManger:(XYManager *)centralManger characteristic:(CBCharacteristic *)characteristic recievedData:(NSData *)data;

// 写入 Peripheral 结束，如果错误则返回 error
- (void)centralManger:(XYManager *)centralManger writeFinishWithError:(NSError *)error;

//-------------------------------------------------------------------------------------------------------//

// 发现服务错误
- (void)centralManger:(XYManager *)centralManger discoverServicesError:(NSError *)error;

// 发现特性错误
- (void)centralManger:(XYManager *)centralManger discoverCharacteristicsError:(NSError *)error;

// 发现数据错误
- (void)centralManger:(XYManager *)centralManger updateValueForCharacteristicError:(NSError *)error;

// 更新通知错误
- (void)centralManger:(XYManager *)centralManger updateNotificationStateForCharacteristicError:(NSError *)error;

// 自动连接错误
- (void)centralManger:(XYManager *)centralManger autoConnectError:(NSError *)error;

@end

@interface XYManager : NSObject

@property (weak, nonatomic) id <XYManagerDelegate> delegate;
@property (assign, nonatomic) BOOL isConnected; ///< 当前是否是连接状态
@property (assign, nonatomic) BOOL isBleOpen; ///手机蓝牙状态
@property (strong, nonatomic) CBCharacteristic *writeCharacteristic; ///< 需要写入的 chaeacteristic
@property (nonatomic, copy) NSString *connectDeviceName; /// 连接设备的名称
@property (nonatomic, assign) BOOL isAutoConnect; /// 自动连接 默认不自动连接
@property (nonatomic, assign) NSInteger timeOutInterval; /// 超时时间
@property (nonatomic, assign) BOOL isAutoScan; /// 自动连接 默认不自动连接


/// 单例对象
+ (XYManager *)instance;

/// 释放单例对象
- (void)destoryInstance;

// 开始扫描
- (void)startScan;

// 停止扫描
- (void)stopScan;

// 选择一个 Peripheral
- (void)connectPeripheral:(CBPeripheral *)peripheral;

// 断开连接
- (void)disconnectWithPeripheral:(CBPeripheral *)peripheral;

// 向蓝牙发送数据
- (void)sendData:(NSData *)data;

@end
