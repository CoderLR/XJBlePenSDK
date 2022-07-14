//
//  XYManager.m
//  KJBleSDKDemo
//
//  Created by yangshuai on 2020/11/18.
//  Copyright © 2020 CoderYS. All rights reserved.
//

#import "XYManager.h"

#define XY_ERROR_CODE(description, errorCode) [NSError errorWithDomain:@"com.zxy.board" code:errorCode userInfo:@{NSLocalizedDescriptionKey:description}]

typedef enum : NSUInteger {
    KJTimeOutTypeScan         = 0,
    KJTimeOutTypeConnect      = 1,
    KJTimeOutTypeAutoConnect  = 2
    
} KJTimeOutType;

/// 蓝牙连接错误码
static NSInteger const XYCentralErrorCodeScanTimeOut = 1000; // 扫描超时
static NSInteger const XYCentralErrorCodeConnectTimeOut = 1001; // 连接超时
static NSInteger const XYCentralErrorCodeBluetoothPowerOff = 1002; // 蓝牙关闭
static NSInteger const XYCentralErrorCodeBluetoothOtherState = 1003; // 除了蓝牙打开关闭的其他状态
static NSInteger const XYCentralErrorCodeAutoConnectFail = 1004; // 自动连接失败
static NSInteger const XYCentralErrorCodeWriteDataLength = 1005; // 写如数据不正确
static NSInteger const XYCentralErrorCodeAutoConnectTimeOut = 1006; // 自动连接超时

// 设备SN
static NSString * const LastDeviceSNIdentifierConnectedKey = @"LastDeviceSNIdentifierConnectedKey";
// 设备名
static NSString * const LastDeviceNameIdentifierConnectedKey = @"LastDeviceNameIdentifierConnectedKey";
// 蓝牙UUID
static NSString * const LastPeriphrealIdentifierConnectedKey = @"LastPeriphrealIdentifierConnectedKey";

@interface XYManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;

// 找到的所有的 Peripheral
@property (strong, nonatomic) NSMutableArray *discoveredPerInfos;

// 当前已经连接的 Peripheral
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;

///< 上一次连接上的 Peripheral，用来做自动连接时，保存强引用
@property (strong, nonatomic) CBPeripheral *lastConnectedPeripheral;

///< 连接的所有 characteristic，主要用于断开连接时，取消 notify 监听
@property (strong, nonatomic) NSMutableArray *readCharacteristics;

@property (strong, nonatomic) NSTimer *timeoutTimer;

///< 将允许搜索的 service UUID 打包为数组 CBUUID 类型
@property (copy, nonatomic) NSArray *serviceUUIDArray;

///< 将允许搜索的 characteristic UUID 打包为数组 CBUUID 类型
@property (copy, nonatomic) NSArray *characteristicUUIDArray;

@end

@implementation XYManager

#pragma mark - Left Cycle
static XYManager *manager = nil;
static dispatch_once_t onceToken;

#pragma mark - 单列初始化
+ (XYManager *)instance {
    if ( manager == nil ){
        dispatch_once(&onceToken, ^{
            manager = [[XYManager alloc] init];
        });
    }
    return manager;
}

- (instancetype)init {

    if (self = [super init]) {
        self.timeOutInterval = 30; // 默认30s
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey:[NSNumber numberWithBool:NO]}];
    }
    return self;
}

/// 释放单例对象
- (void)destoryInstance {
    [self stopScan];
    [self stopTimer];
    onceToken = 0;
    manager = nil;
}

#pragma mark - Public Methods

/// 扫描外设
- (void)startScan {
    
    if (self.discoveredPerInfos.count) {
        [self.discoveredPerInfos removeAllObjects];
    }

    [self.centralManager scanForPeripheralsWithServices: nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@(NO)}];
    [self startTimer:KJTimeOutTypeScan];
}

/// 停止扫描
- (void)stopScan {
    if (self.centralManager.isScanning) {
        [self.centralManager stopScan];
    }
}

/// 连接外设
/// @param peripheral 外设对象
- (void)connectPeripheral:(CBPeripheral *)peripheral {

    NSLog(@"connect = %@",peripheral);
    
    [self.centralManager connectPeripheral:peripheral options:nil];

    [self startTimer:KJTimeOutTypeConnect];
}

/// 向蓝牙发送数据
/// @param data 二进制手数据
- (void)sendData:(NSData *)data {
    
    if (!self.writeCharacteristic || !self.isConnected) {
        return;
    }
    NSLog(@"write:%@",data);
    if (data == nil || data.length == 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:writeFinishWithError:)]) {

            NSError *error = XY_ERROR_CODE(XYCentralErrorWriteDataLength, XYCentralErrorCodeWriteDataLength);
            [self.delegate centralManger:self writeFinishWithError:error];
        }
        return;
    }
 
    [self.connectedPeripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
}

/// 与蓝牙外设断开连接
/// @param peripheral 外设对象
- (void)disconnectWithPeripheral:(CBPeripheral *)peripheral {
    for (CBCharacteristic *characteristic in self.readCharacteristics) {
        [self.connectedPeripheral setNotifyValue:NO forCharacteristic:characteristic];
    }
    [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
    self.connectedPeripheral = nil;
}

#pragma mark - Private Methods

/// 自动连接
- (void)autoConnect {
    // 取出上次连接成功后，存的 peripheral identifier
    NSString *lastPeripheralIdentifierConnected = [[NSUserDefaults standardUserDefaults] objectForKey:LastPeriphrealIdentifierConnectedKey];

    // 如果没有，则不做任何操作，说明需要用户点击开始扫描的按钮，进行手动搜索
    if (lastPeripheralIdentifierConnected == nil || lastPeripheralIdentifierConnected.length == 0) {
        return;
    }
    // 查看上次存入的 identifier 还能否找到 peripheral
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:lastPeripheralIdentifierConnected];
    NSArray *peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[uuid]];
    // 如果不能成功找到或连接，可能是设备未开启等原因，返回连接错误
    if (peripherals == nil || [peripherals count] == 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:autoConnectError:)]) {
            NSError *error = XY_ERROR_CODE(XYCentralErrorConnectAutoConnectFail, XYCentralErrorCodeAutoConnectFail);
            [self.delegate centralManger:self autoConnectError:error];
        }
        return;
    }
    // 如果能找到则开始建立连接
    CBPeripheral *peripheral = [peripherals firstObject];
    [self.centralManager connectPeripheral:peripheral options:nil];
    // 注意保留 Peripheral 的引用
    self.lastConnectedPeripheral = peripheral;
    [self startTimer:KJTimeOutTypeAutoConnect];
}

#pragma mark - Timer

/// 开启定时器
/// @param type 类型
- (void)startTimer:(KJTimeOutType)type {
    [self stopTimer];

    NSTimer *timer = [NSTimer timerWithTimeInterval:self.timeOutInterval target:self selector:@selector(timeOut:) userInfo:@(type) repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    _timeoutTimer = timer;
}

/// 停止定时器
- (void)stopTimer {
    if (_timeoutTimer != nil) {
        [_timeoutTimer invalidate];
        _timeoutTimer = nil;
    }
}

/// 扫描超时
/// @param timer timer
- (void)timeOut:(NSTimer *)timer {

    NSInteger type = [timer.userInfo integerValue];
    if (type == KJTimeOutTypeScan) {
        [self stopScan];
    }
    
    if (type == KJTimeOutTypeScan) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:scanTimeOut:)]) {
            NSError *error = XY_ERROR_CODE(XYCentralErrorScanTimeOut, XYCentralErrorCodeScanTimeOut);
            [self.delegate centralManger:self scanTimeOut:error];
        }
    } else if (type == KJTimeOutTypeConnect) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:connectTimeOut:)]) {
            NSError *error = XY_ERROR_CODE(XYCentralErrorConnectTimeOut, XYCentralErrorCodeConnectTimeOut);
            [self.delegate centralManger:self connectTimeOut:error];
        }
    } else if (type == KJTimeOutTypeAutoConnect) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:autoConnectTimeOut:)]) {
            NSError *error = XY_ERROR_CODE(XYCentralErrorAutoConnectTimeOut, XYCentralErrorCodeAutoConnectTimeOut);
            [self.delegate centralManger:self autoConnectTimeOut:error];
        }
    }
}

#pragma mark - CBCentralManagerDelegate

/// 手机蓝牙是否打开
/// @param central 蓝牙manager
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    // CBCentralManagerStatePoweredOn 是唯一正常的状态
    if (central.state == CBManagerStatePoweredOn) {
        NSLog(@"蓝牙已打开");
        self.isBleOpen = YES;
        return;
    } else if (central.state == CBManagerStatePoweredOff) {
        self.isBleOpen = NO;
        NSLog(@"蓝牙已关闭");
    }
    // 其他状态都是错的
    if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:bluetoothStatus:)]) {
        // 如果蓝牙关闭了
        if (central.state == CBManagerStatePoweredOff) {
            NSError *error = XY_ERROR_CODE(XYCentralErrorBluetoothPowerOff, XYCentralErrorCodeBluetoothPowerOff);
            [self.delegate centralManger:self bluetoothStatus:error];
        } else {
            // 还有当前设备不支持、未知错误等，统一为其它错误
            NSError *error = XY_ERROR_CODE(XYCentralErrorBluetoothOtherState, XYCentralErrorCodeBluetoothOtherState);
            [self.delegate centralManger:self bluetoothStatus:error];
        }
    }
}

/// 发现蓝牙设备
/// @param central 蓝牙manager
/// @param peripheral 蓝牙外设
/// @param advertisementData 字典
/// @param RSSI 信号强度
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {

    // 将找到的 peripheral 存入数组
    //NSLog(@"device_name = %@",peripheral.name);
    //NSLog(@"idf = %@",peripheral.identifier.UUIDString);
    //NSLog(@"advertisementData = %@",advertisementData);
    
    // 筛选蓝牙设备
    if ([peripheral.name.uppercaseString hasPrefix:@"ZXY"] || [peripheral.name.uppercaseString hasPrefix:@"XJ"]) {
        // 发现新设备
        if (![self.discoveredPerInfos containsObject:peripheral]) {
            [self.discoveredPerInfos addObject:peripheral];
        }

        // 找到设备的回调
        if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:findPeripherals:)]) {
            [self.delegate centralManger:self findPeripherals:self.discoveredPerInfos];
        }
    }
}

/// 连接外设成功回调
/// @param central 蓝牙manager
/// @param peripheral 蓝牙外设
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self stopTimer];
    [self stopScan];
    peripheral.delegate = self;
    
    self.connectedPeripheral = peripheral; // 存储设备信息
    self.connectDeviceName = peripheral.name; // 存储设备名
    
    [peripheral discoverServices:self.serviceUUIDArray];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:connectSuccess:)]) {
        [self.delegate centralManger:self connectSuccess:peripheral];
    }
}

/// 连接失败（但不包含超时，系统没有超时处理）
/// @param central 蓝牙manager
/// @param peripheral 蓝牙外设
/// @param error error
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self stopTimer];
    [self stopScan];
    
    if (error && self.delegate && [self.delegate respondsToSelector:@selector(centralManger:connectFailure:)]) {
        [self.delegate centralManger:self connectFailure:error];
    }
}

/// 外设断开蓝牙连接
/// @param central 蓝牙manager
/// @param peripheral 蓝牙外设
/// @param error error
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    
    NSLog(@"now = %@",peripheral);
    NSLog(@"error:%@",error);
    
//    for (CBCharacteristic *characteristic in self.readCharacteristics) {
//        [self.connectedPeripheral setNotifyValue:NO forCharacteristic:characteristic];
//    }
//    self.connectedPeripheral = nil;
    // 重新连接
//    [self.centralManager connectPeripheral:peripheral options:nil];
    
    [self stopTimer];
    [self stopScan];
    self.connectedPeripheral = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:disconnectPeripheral:)]) {
        [self.delegate centralManger:self disconnectPeripheral:peripheral];
    }
}

#pragma mark - CBPeripheralDelegate

/// 搜索到服务
/// @param peripheral 蓝牙外设
/// @param error error
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:discoverServicesError:)]) {
            [self.delegate centralManger:self discoverServicesError:error];
        }
        return;
    }
    for (CBService *service in peripheral.services) {
        
        NSLog(@"service = %@", service.UUID.UUIDString);
        
        // 对比是否是需要的 service
        if (![self.serviceUUIDArray containsObject:service.UUID]) {
            continue;
        }
        // 如果找到了，就继续找 characteristic
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

/// 搜索到特性
/// @param peripheral 蓝牙外设
/// @param service 蓝牙服务
/// @param error error
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:discoverCharacteristicsError:)]) {
            [self.delegate centralManger:self discoverCharacteristicsError:error];
        }
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"characteristic = %@",characteristic.UUID);
        // 对比是否是需要的 characteristic
        if (![self.characteristicUUIDArray containsObject:characteristic.UUID]) {
            continue;
        }
        
        // 找到可读的 characteristic，就自动读取数据
        if (characteristic.properties & CBCharacteristicPropertyRead) {
            [peripheral readValueForCharacteristic:characteristic];
        }
        if (characteristic.properties & CBCharacteristicPropertyNotify) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            [self.readCharacteristics addObject:characteristic];
        }
        if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {

            _writeCharacteristic = characteristic;
        }
    }
}

/// 读到特性的数据回调
/// @param peripheral 蓝牙外设
/// @param characteristic 蓝牙特性
/// @param error error
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:updateValueForCharacteristicError:)]) {
            [self.delegate centralManger:self updateValueForCharacteristicError:error];
        }
        return;
    }
    
    NSData *value = characteristic.value;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:characteristic:recievedData:)]) {
        [self.delegate centralManger:self characteristic:characteristic recievedData:value];
    }
}

// 设置数据订阅成功（或失败）
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:updateNotificationStateForCharacteristicError:)]) {
            [self.delegate centralManger:self updateNotificationStateForCharacteristicError:error];
        }
        return;
    }
    
    // 读特性
    if (characteristic.properties & CBCharacteristicPropertyRead) {
        //如果具备通知，即可以读取特性的value
        [peripheral readValueForCharacteristic:characteristic];
    }
}

// 接收到数据写入结果的回调 （写入数据调用）
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    if (self.delegate && [self.delegate respondsToSelector:@selector(centralManger:writeFinishWithError:)]) {
        [self.delegate centralManger:self writeFinishWithError:error];
        return;
    }
}

#pragma mark - Getter / Setter

- (NSMutableArray *)discoveredPerInfos {
    if (!_discoveredPerInfos) {
        _discoveredPerInfos = [NSMutableArray new];
    }
    return _discoveredPerInfos;
}

- (NSMutableArray *)readCharacteristics {
    if (!_readCharacteristics) {
        _readCharacteristics = [NSMutableArray new];
    }
    return _readCharacteristics;
}

- (NSArray *)serviceUUIDArray {
    if (!_serviceUUIDArray) {
        CBUUID *serviceUUID1 = [CBUUID UUIDWithString: ZXY_SERVICE_UUID];
        _serviceUUIDArray = @[serviceUUID1];
    }
    return _serviceUUIDArray;
}

- (NSArray *)characteristicUUIDArray {
    if (!_characteristicUUIDArray) {
        CBUUID *characteristicUUID1 = [CBUUID UUIDWithString: ZXY_CHARACTERISTIC_UUID_RED];
        CBUUID *characteristicUUID2 = [CBUUID UUIDWithString: ZXY_CHARACTERISTIC_UUID_WRITE];
        _characteristicUUIDArray = @[characteristicUUID1, characteristicUUID2];
    }
    return _characteristicUUIDArray;
}

- (void)setConnectedPeripheral:(CBPeripheral *)connectedPeripheral {
    _connectedPeripheral = connectedPeripheral;
    // 如果当前的 peripheral 不为空 并且 设置了自动连接，则记录 identifier，为自动连接做准备
    if (connectedPeripheral != nil && self.isAutoConnect) {
        [[NSUserDefaults standardUserDefaults] setObject:connectedPeripheral.identifier.UUIDString forKey:LastPeriphrealIdentifierConnectedKey];
    }
}

- (void)setConnectDeviceName:(NSString *)connectDeviceName {
    _connectDeviceName = connectDeviceName;
    
    if (![connectDeviceName isEqualToString:@""] && connectDeviceName != nil && self.isAutoConnect) {
        [[NSUserDefaults standardUserDefaults] setObject:connectDeviceName forKey:LastDeviceNameIdentifierConnectedKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)setIsAutoConnect:(BOOL)isAutoConnect {
    _isAutoConnect = isAutoConnect;
    // 如果设置了自动连接
    if (isAutoConnect) {
        // 这里需要延迟 0.1s 才能走连接成功的代理，具体原因未知
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self autoConnect];
        });
    }
}

- (void)setTimeOutInterval:(NSInteger)timeOutInterval {
    _timeOutInterval = timeOutInterval;
}

- (void)setIsAutoScan:(BOOL)isAutoScan {
    _isAutoScan = isAutoScan;
    
    if (self.isBleOpen) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startScan];
        });
    }
}

- (BOOL)isConnected {
    if (self.connectedPeripheral == nil) {
        return NO;
    }
    return self.connectedPeripheral.state == CBPeripheralStateConnected;
}

@end

//特征值的属性 枚举如下
/*
 typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
 CBCharacteristicPropertyBroadcast,//允许广播特征
 CBCharacteristicPropertyRead,//可读属性
 CBCharacteristicPropertyWriteWithoutResponse,//可写并且接收回执
 CBCharacteristicPropertyWrite,//可写属性
 CBCharacteristicPropertyNotify,//可通知属性
 CBCharacteristicPropertyIndicate,//可展现的特征值
 CBCharacteristicPropertyAuthenticatedSignedWrites,//允许签名的特征值写入
 CBCharacteristicPropertyExtendedProperties,
 CBCharacteristicPropertyNotifyEncryptionRequired,
 CBCharacteristicPropertyIndicateEncryptionRequired
 };
*/
