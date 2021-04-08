//
//  ZXYBSdk.m
//  XJBleSDKDemo
//
//  Created by yangshuai on 2020/11/18.
//  Copyright © 2020 CoderYS. All rights reserved.
//

#import "ZXYBSdk.h"
#import "XYManager.h"
#import "XYConstant.h"

// API版本
static NSString * const zxyApiVerson = @"1.0.5-20200406";

@interface ZXYBSdk () <XYManagerDelegate>

// 0 A4 1 A5
// private int self.boardType = 1;
@property (nonatomic, assign) int boardType;

// 0 横屏 1 竖屏
@property (nonatomic, assign) int oriention;

// 工作区域
@property (nonatomic, assign) CGSize workSize;

@property (nonatomic, assign) int last_penX;
@property (nonatomic, assign) int last_penY;
@property (nonatomic, assign) int g_leftSize;

@property (nonatomic, assign) Byte *g_bufferData;

@end

@implementation ZXYBSdk

static int last_penStatus = 4;

static ZXYBSdk *manager = nil;
static dispatch_once_t onceToken;

#pragma mark - 单列初始化
+ (ZXYBSdk *)instance {
    if ( manager == nil ){
        dispatch_once(&onceToken, ^{
            manager = [[ZXYBSdk alloc] init];
        });
    }
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        [XYManager instance].delegate = self;
        
        // 0 A4 1 A5
        self.boardType = 1;
        
        // 1 竖屏 0 横屏
        self.oriention = 1;
        
        // 工作区域
        self.workSize = CGSizeMake(K_PX_WIDTH, K_PX_HEIGHT);
        
        self.last_penX = 0;
        self.last_penY = 0;
        self.g_leftSize = 0;
        
        self.g_bufferData = (Byte *)malloc(50);
    }
    return self;
}

/// 释放单例对象
- (void)destoryInstance {
    [XYManager instance].delegate = nil;
    onceToken = 0;
    manager = nil;
    [[XYManager instance] destoryInstance];
}

/// API版本
+ (NSString *)getApiVersion {
    return zxyApiVerson;
}

/// 是否自动连接
/// @param isAutoConnect 自动连接
- (void)XYInit:(BOOL)isAutoConnect {
    [XYManager instance].isAutoConnect = isAutoConnect;
}

/// 设置超时时间
/// @param timeInterval 超时时间
- (void)XYSetTimeOutInterval:(NSInteger)timeInterval {
    [XYManager instance].timeOutInterval = timeInterval;
}

/// 设置工作区域
/// @param size App坐标
- (void)XYSetWorkRegion:(CGSize)size {
    CGFloat width = size.height;
    CGFloat height = size.width;
    self.workSize = CGSizeMake(width, height);
}

/// 设置XY坐标的横纵向
/// @param orient 默认为0 横向 1：纵向
- (void)setOrientation:(int)orient {
    self.oriention = orient;
}

#pragma mark - Bluetool
/// 开始扫描蓝牙
- (void)scanBluetool {
    [[XYManager instance] startScan];
}

/// 停止扫描
- (void)stopScan {
    [[XYManager instance] stopScan];
}

/// 蓝牙连接状态
- (BOOL)isConnected {
    return [XYManager instance].isConnected;
}

/// 手机蓝牙是否打开
- (BOOL)isBleOpen {
    return [XYManager instance].isBleOpen;
}

/// 连接设备
/// @param peripheral 外设对象
- (void)connect:(CBPeripheral *)peripheral {
    [[XYManager instance] connectPeripheral:peripheral];
}

/// 断开连接（用户主动）
/// @param peripheral 外设对象
- (void)disconnect:(CBPeripheral *)peripheral {
    [[XYManager instance] disconnectWithPeripheral:peripheral];
}

/// 向蓝牙发送数据
- (void)sendData:(NSData *)data {
    [[XYManager instance] sendData:data];
}

#pragma mark - XYManagerDelegate

// 蓝牙状态
- (void)centralManger:(XYManager *)centralManger bluetoothStatus:(NSError *)error {
    
}

// 找到 Peripheral，没找到一个都会返回全部 Peripheral 的数组
- (void)centralManger:(XYManager *)centralManger findPeripherals:(NSMutableArray *)peripherals {
    NSLog(@"peripherals = %@", peripherals);
    if (self.delegate) {
        [self.delegate onScanDevice:peripherals];
    }
}

// 收到 Peripheral 发过来的数据
- (void)centralManger:(XYManager *)centralManger characteristic:(CBCharacteristic *)characteristic recievedData:(NSData *)data {
    if (data.length == 0) { return; }
    [self getBoardData:data];
}

// 连接失败
- (void)centralManger:(XYManager *)centralManger connectFailure:(NSError *)error {
    NSLog(@"连接失败 = %@", error);
    if (self.delegate) {
        [self.delegate onXYEnvNotifyProc:ZXYBleConnectFail];
    }
}

// 连接成功（仅仅是 Peripheral 连接成功，如果内部的 Service 或者 Characteristic 连接失败，会走失败代理）
- (void)centralManger:(XYManager *)centralManger connectSuccess:(CBPeripheral *)peripheral {
    NSLog(@"连接成功 = %@", peripheral);
    if (self.delegate) {
        [self.delegate onXYEnvNotifyProc:ZXYBleConnectSuccess];
    }
}

// 断开连接（准备断开就会走这个方法，具体是否真正断开要看苹果底层的实现，如果有其他 app 正连接着，不会断开）
- (void)centralManger:(XYManager *)centralManger disconnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"断开连接 = %@", peripheral);
    if (self.delegate) {
        [self.delegate onXYEnvNotifyProc:ZXYBleDisconnect];
    }
}

// 扫描外设超时 默认扫描30s
- (void)centralManger:(XYManager *)centralManger scanTimeOut:(NSError *)error {
    NSLog(@"扫描超时 = %@", error);
    if (self.delegate) {
        [self.delegate onXYEnvNotifyProc:ZXYBleScanTimeOut];
    }
}

// 连接超时 默认30s
- (void)centralManger:(XYManager *)centralManger connectTimeOut:(NSError *)error {
    NSLog(@"连接超时 = %@", error);
    if (self.delegate) {
        [self.delegate onXYEnvNotifyProc:ZXYBleConnectTimeOut];
    }
}

// 发现服务错误
- (void)centralManger:(XYManager *)centralManger discoverServicesError:(NSError *)error {
    NSLog(@"发现服务错误 = %@", error);
}

// 发现特性错误
- (void)centralManger:(XYManager *)centralManger discoverCharacteristicsError:(NSError *)error {
    NSLog(@"发现特性错误 = %@", error);
}

// 发现数据错误
- (void)centralManger:(XYManager *)centralManger updateValueForCharacteristicError:(NSError *)error {
    NSLog(@"发现数据错误 = %@", error);
}

// 更新通知错误
- (void)centralManger:(XYManager *)centralManger updateNotificationStateForCharacteristicError:(NSError *)error {
    NSLog(@"更新通知错误 = %@", error);
}

// 自动连接错误
- (void)centralManger:(XYManager *)centralManger autoConnectError:(NSError *)error {
    NSLog(@"自动连接错误 = %@", error);
    if (self.delegate) {
        [self.delegate onXYEnvNotifyProc:ZXYBleAutoConnectError];
    }
}

#pragma mark - 蓝牙数据解析
- (void)getBoardData:(NSData *)drawData {
    Byte *tmpData = (Byte *)[drawData bytes];
    int left = self.g_leftSize;
    int num = (int)drawData.length + left;
    int index = 0;
    int start = 0;
    [self bytesplit2byte:tmpData orc:self.g_bufferData sbegin:0 obegin:left count:drawData.length];
    Byte *g_bufferData = self.g_bufferData;
    NSData *bufferData =[NSData dataWithBytes:g_bufferData length:50];
    BOOL flag = false;
    if (bufferData.length > 0) {
        while (index + 10 <= num) {
            int prefix = [self byteToInt1:g_bufferData[index] low:g_bufferData[index + 1]];
//            Log.e("ActionLog", "111:" + FmtTools.bytesToHexString(g_bufferData));
            if (prefix == 0xfdfd || prefix == 0xfdfe) {
                if (index + 10 == num) {
                    flag = true;
                } else if (index + 12 <= num) {
//                    Log.e("ActionLog", "index:" + index);
                    if ([self byteToInt:g_bufferData[index + 10] low:g_bufferData[index + 11]] == 0xfdfd || [self byteToInt1:g_bufferData[index + 10] low:g_bufferData[index + 11]] == 0xfdfe) {
                        flag = true;
                    }
                }
                if (flag) {
                    int type = (int) (g_bufferData[index + 2] & 0x0FF);
                    int mode = (int) (g_bufferData[index + 3] & 0x0FF);
                    int bleX = [self byteToInt:g_bufferData[index + 4] low:g_bufferData[index + 5]];
                    int bleY = [self byteToInt:g_bufferData[index + 6] low:g_bufferData[index + 7]];
                    NSLog(@"");
//                    Log.e("ActionLog", "ActionLog type:" + type);
                    int key = -1;
                    //硬件按钮
                    int btnIndex = bleX;
                    //软件按钮
//                    Log.e("buttonLog", "btnIndex:" + bleX);
                    int tmpBtn = [self byteToInt:g_bufferData[index + 5] low:g_bufferData[index + 6]];
                    if (self.boardType == 1) {
                        btnIndex = tmpBtn;
                    }
                    int blePressure = [self byteToInt:g_bufferData[index + 8] low:g_bufferData[index + 9]];
                    // Log.e("fffLog","keyIndex:"+keyIndex);
                    index += 10;
                    start = index;
//                    Log.i(TAG, "onBLECharacteristicChanged: mode:" + mode);
                    if (mode == 0xa1 || (mode == 0x1 && type == 2)) {
                        if (last_penStatus == XYPenStatus_Hover || last_penStatus == XYPenStatus_Leave) {
                            last_penStatus = XYPenStatus_Down;
//                            Log.e("AcionLog", "XYPenStatus_Down");
                        } else {
                            last_penStatus = XYPenStatus_Move;
                        }
                    } else if (mode == 0xa0 || (mode == 0x2 && type == 2)) {
                        if (last_penStatus == XYPenStatus_Down || last_penStatus == XYPenStatus_Move) {
                            last_penStatus = XYPenStatus_Up;
//                            Log.e("AcionLog", "XYPenStatus_Move");
                        } else {
                            last_penStatus = XYPenStatus_Hover;
                        }
                    } else if (mode == 0xc0 || (mode == 0x0 && type == 2)) {
                        if (last_penStatus == XYPenStatus_Down || last_penStatus == XYPenStatus_Move) {
                            last_penStatus = XYPenStatus_Up;
//                            Log.e("AcionLog", "XYPenStatus_up");
                        } else {
                            last_penStatus = XYPenStatus_Leave;
                        }
                    } else if (mode == 0xf0 || type == 1) {

//                        Log.i(TAG, "onBLECharacteristicChanged: 点击按键" + btnIndex);
                        if (prefix == 0xfdfe) {
                            if (self.delegate) {
                                [self.delegate onKeySoftKeyCallBack:btnIndex isDown:mode == 1];
                            }
                        } else {
                            key = btnIndex;
//                            Log.i(TAG, "onBLECharacteristicChanged: keyIndex " + btnIndex);
                            if (self.delegate) {
                                [self.delegate onKeySoftKeyCallBack:btnIndex isDown:mode >= 1];
                            }
                            if (btnIndex != 0) {
                                if (self.delegate) {
                                    [self.delegate onBtnIndexCallBack:btnIndex];
                                }
                            }
                        }
                    }
                    BOOL filtered = false;
                    if (last_penStatus == XYPenStatus_Move || last_penStatus == XYPenStatus_Hover) {
                        if (abs(bleX - self.last_penX) <= 5 && abs(bleY - self.last_penY) <= 5) {
                            filtered = true;
                        }
                    }
                    if (!filtered) {
                        XYDataPacket *packet = [[XYDataPacket alloc] init];
                        if (self.oriention == PORTRAIT) {
                            if (prefix == 0xfdfe) {
//                                Log.e("AAALog", "222222:" + self.boardType);
                                if (self.boardType == 0) {
                                    packet.x = bleX;
                                    packet.y = bleY;
                                    CGFloat tx = (int) (packet.x * self.workSize.width / K_A4_WIDTH);
                                    CGFloat ty = (int) (packet.y * self.workSize.height / K_A4__HEIGHT);
                                    CGPoint point = [self convert:tx y:ty];
                                    packet.tx = point.x;
                                    packet.ty = point.y;
                                } else {
                                    packet.x = bleX;
                                    packet.y = bleY;
                                    CGFloat tx = (int) (packet.x * self.workSize.width / K_A5_WIDTH);
                                    CGFloat ty = (int) (packet.y * self.workSize.height / K_A5_HEIGHT);
                                    CGPoint point = [self convert:tx y:ty];
                                    packet.tx = point.x;
                                    packet.ty = point.y;
                                }

                            } else {
                                CGFloat tx = (int) (bleX * self.workSize.width / K_XX_HEIGHT);
                                CGFloat ty = (int) (bleY * self.workSize.height / K_XX_WIDTH);
                                CGPoint point = [self convert:tx y:ty];
                                packet.tx = point.x;
                                packet.ty = point.y;
                            }
                        } else {

                            if (prefix == 0xfdfe) {
//                                Log.e("AAALog", "11111111111111:" + self.boardType);
                                if (self.boardType == 0) {
                                    packet.x = K_A4__HEIGHT - bleY;
                                    packet.y = bleX;
                                    CGFloat tx = (int) (packet.x * self.workSize.width / K_A4__HEIGHT);
                                    CGFloat ty = (int) (packet.y * self.workSize.height / K_A4_WIDTH);
                                    CGPoint point = [self convert:tx y:ty];
                                    packet.tx = point.x;
                                    packet.ty = point.y;
                                } else {
                                    packet.x = K_A5_HEIGHT - bleY;
                                    packet.y = bleX;
                                    CGFloat tx = (int) (packet.x * self.workSize.width / K_A5_HEIGHT);
                                    CGFloat ty = (int) (packet.y * self.workSize.height / K_A5_WIDTH);
                                    CGPoint point = [self convert:tx y:ty];
                                    packet.tx = point.x;
                                    packet.ty = point.y;
                                }
                            } else {
                                CGFloat tx = (int) (bleX * self.workSize.width / K_XX_WIDTH);
                                CGFloat ty = (int) (bleY * self.workSize.height / K_XX_HEIGHT);
                                CGPoint point = [self convert:tx y:ty];
                                packet.tx = point.x;
                                packet.ty = point.y;
                            }
                        }
//                        Log.e("AAALog", "xxxx:" + bleX);

                        packet.pressure = blePressure;
                        packet.penStatus = last_penStatus;
                        packet.buttonIndex = key;
                        if (self.delegate) {
                            [self.delegate onXYPackDataProc:packet];
                        }
                        self.last_penX = bleX;
                        self.last_penY = bleY;
                        //"3|100,200|102,202|300,400"
                        //压力值需>0时记录
                    }
                }
            } else if (prefix == 0xfefe) {

                int commd = (g_bufferData[index + 2] & 0x0FF);

                int bodylen = [self byteToInt1:g_bufferData[index + 3] low:g_bufferData[index + 4]];

//                Log.e("IndexLog", "bodylen:" + bodylen);

                if (commd == 0x61) {
                    int type = (g_bufferData[index + 7] & 0x0FF);
                    int mX = [self byteToInt1:g_bufferData[index + 8] low:g_bufferData[index + 9]];
                    int mY = [self byteToInt1:g_bufferData[index + 10] low:g_bufferData[index + 11]];
                    int p = [self byteToInt1:g_bufferData[index + 12] low:g_bufferData[index + 13]];
//                    Log.e("Adlog", "type:" + type + " mx:" + mX + " my:" + mY + " p:" + p);

                    if (self.delegate) {
                        XYBoardInfo *info = [[XYBoardInfo alloc] init];
                        info.boardType = type;
                        info.maxX = mX;
                        info.maxY = mY;
                        info.pressure = p;
                        [self.delegate onBackBoardInfo:info];
                    }

                    [self writeCharacteristic];
                    // writeCharacteristic("fefe6700000000");
                }
//                Log.e("IndexLog", "index:" + index);
                if (index + 7 + bodylen <= num) {
                    flag = true;
                    index += 7;
                    index += bodylen;
                    start = index;
                } else {
                    break;
                }

            }
            if (!flag) {
                index += 1;
            }
        }
        left = num - start;
//        Log.e("IndexLog", "num:" + num);
//        Log.e("IndexLog", "start:" + start);
//        Log.e("IndexLog", "left111:" + left);
        if (start < num && left > 0) {
//            Log.e("IndexLog", "copy前数据：" + FmtTools.bytesToHexString(g_bufferData));
//            System.arraycopy(g_bufferData, start, g_bufferData, 0, left);
            [self bytesplit2byte:self.g_bufferData orc:self.g_bufferData sbegin:start obegin:0 count:left];
//            Log.e("IndexLog", "copy后数据：" + FmtTools.bytesToHexString(g_bufferData));
        }
        self.g_leftSize = left;

    }

}

#pragma mark - Tools

// 向蓝牙发送数据
- (void)writeCharacteristic {
    // fe fe 66 00 01 00 00 01
    Byte byte[] = {0xfe, 0xfe, 0x66, 0x00, 0x01, 0x00, 0x00, 0x01};
    NSData *data =  [NSData dataWithBytes:byte length:8];
    [self sendData:data];
}

// 坐标转换为手机坐标点
- (CGPoint)convert:(CGFloat)x y:(CGFloat)y {
    CGFloat sx = self.workSize.width - x;
    CGFloat sy = y;
    return CGPointMake(sy, sx);
}

// 数组拷贝
- (void)bytesplit2byte:(Byte[])src orc:(Byte[])orc sbegin:(NSInteger)sbegin obegin:(NSInteger)obegin count:(NSInteger)count{
    memset(orc, 0, sizeof(char)*count);
    for (NSInteger i = sbegin; i < sbegin + count; i++){
        orc[i - sbegin + obegin] = src[i];
    }
}

- (int)byteToInt:(Byte)b0 low:(Byte)b1 {
    int s = 0;
    int s0 = (int)(b0 & 0xff);
    int s1 = (int)(b1 & 0xff);
    s1 <<= 8;
    s = (int) (s0 | s1);
    return  s;
}

- (int)byteToInt1:(Byte)b0 low:(Byte)b1 {
    int s = 0;
    int s0 = (int)(b0 & 0xff);
    int s1 = (int)(b1 & 0xff);
    s0 <<= 8;
    s = (int) (s0 | s1);
    return  s;
}

@end
