//
//  ViewController.m
//  XJBleSDKDemo
//
//  Created by yangshuai on 2019/11/26.
//  Copyright © 2019 CoderYS. All rights reserved.
//

#import "DeviceViewController.h"
#import "MBProgressHUD+KJExtension.h"
#import "DrawView.h"
#import <XJBleSDK/XJBleSDK.h>

#define KScreenWidth [UIScreen mainScreen].bounds.size.width
#define KScreenHeight [UIScreen mainScreen].bounds.size.height
#define KStatusBarH [UIApplication sharedApplication].statusBarFrame.size.height
#define KNavigationBarH (KStatusBarH + 44.f)
#define KColor(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

@interface DeviceViewController () <UITableViewDelegate, UITableViewDataSource, ZXYBSdkDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) UIView *bgView;
@property (nonatomic, weak) DrawView *drawView;
@property (nonatomic, weak) UIButton *closeBtn;

@property (nonatomic, strong) NSMutableArray *peripheralInfos;

@property (nonatomic, strong) NSData *fileData;
@property (nonatomic, copy) NSString *fileName;

@end

@implementation DeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [ZXYBSdk instance].delegate = self;
    //[[ZXYBSdk instance] XYInit:YES];
}

- (void)addDrawView {
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    
    UIView *bgView = [[UIView alloc] initWithFrame:keyWindow.bounds];
    bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    [keyWindow addSubview:bgView];
    self.bgView = bgView;
    
    DrawView *drawView = [[DrawView alloc] initWithFrame:CGRectZero];
    CGFloat width = KScreenWidth;
    CGFloat height = width * 10 / 7;
    drawView.size = CGSizeMake(width, height);
    drawView.centerY = KScreenHeight * 0.5 - 20;
    drawView.backgroundColor = KColor(70, 113, 84);
    [bgView addSubview:drawView];
    self.drawView = drawView;
    
    [[ZXYBSdk instance] XYSetWorkRegion:CGSizeMake(width, height)];
    NSLog(@"画板大小-----%@", NSStringFromCGSize(CGSizeMake(width, height)));
    
    UIButton *closeBtn = [[UIButton alloc] init];
    [closeBtn setBackgroundImage:[UIImage imageNamed:@"icon_close"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside]; // 按钮事件
    closeBtn.size = CGSizeMake(25, 25);
    closeBtn.centerX = drawView.width * 0.5;
    closeBtn.y = drawView.bottom + 10;
    [bgView addSubview:closeBtn];
    self.closeBtn = closeBtn;
}

- (void)closeBtnClick:(UIButton *)btn {
    
    [self.bgView removeFromSuperview];
    
    self.drawView = nil;
    self.closeBtn = nil;
}

#pragma mark - ZXYBSdkDelegate
- (void)onXYPackDataProc:(XYDataPacket *)packet {
//    NSLog(@"x = %d y = %d tx = %d ty = %d penStatus = %d",packet.x, packet.y, packet.tx, packet.ty, packet.penStatus);
    NSLog(@"x = %d y = %d tx = %d ty = %d penStatus = %d",packet.x, packet.y, packet.tx, packet.ty, packet.penStatus);
    if (self.drawView) {
        self.drawView.packet = packet;
    }
}

- (void)onBtnIndexCallBack:(int)btn_index {
    NSLog(@"btn_index = %d",btn_index);
}

- (void)onKeySoftKeyCallBack:(int)btn_index isDown:(BOOL)isDown {
    NSLog(@"btn_index = %d isDown = %d",btn_index, isDown);
    if (isDown) {
        if (!self.drawView) { return; }
        [self boardBtnClick:btn_index];
    }
}

//返回设备的信息参数
- (void)onBackBoardInfo:(XYBoardInfo *)info {
    NSLog(@"boardType = %d maxX = %d maxX = %d pressure = %d",info.boardType, info.maxX, info.maxY, info.pressure);
}

- (void)onXYEnvNotifyProc:(ZXYBleConnectStatus)status {
    NSLog(@"status = %zd", status);
    // 连接成功
    if (status == ZXYBleConnectSuccess) {
        [MBProgressHUD showMessageWithText:@"蓝牙连接成功"];
        [self addDrawView];
    } else if (status == ZXYBleConnectFail) {
        [MBProgressHUD showMessageWithText:@"蓝牙连接失败"];
    } else if (status == ZXYBleDisconnect) {
        [MBProgressHUD showMessageWithText:@"蓝牙连接中断"];
    }
}

// 扫描设备回调
- (void)onScanDevice:(NSArray *)peripherals {
    NSLog(@"peripherals = %@", peripherals);
    self.peripheralInfos = [peripherals mutableCopy];
    [self.tableView reloadData];
}

#pragma mark - Action
- (IBAction)ScanBtnClick:(id)sender {
    
    // 开始扫描设备
    [[ZXYBSdk instance] scanBluetool];
}

- (void)boardBtnClick:(int)index {
    switch (index) {
        case 101:
            [MBProgressHUD showMessageWithText:@"保存操作"];
            break;
        case 102:
            [MBProgressHUD showMessageWithText:@"清屏操作"];
            [self.drawView cleanScreen];
            break;
        case 103:
            [MBProgressHUD showMessageWithText:@"已修改画笔颜色为蓝色"];
            [self.drawView setLineColor:[UIColor blueColor]];
            break;
        case 104:
            [MBProgressHUD showMessageWithText:@"已修改画笔颜色为黑色"];
            [self.drawView setLineColor:[UIColor blackColor]];
            break;
        case 105:
            [MBProgressHUD showMessageWithText:@"已修改画笔颜色为红色"];
            [self.drawView setLineColor:[UIColor redColor]];
            break;
        case 106:
            [MBProgressHUD showMessageWithText:@"已修改画笔为细笔"];
            [self.drawView setLineWidth:1];
            break;
        case 107:
            [MBProgressHUD showMessageWithText:@"已修改画笔为中笔"];
            [self.drawView setLineWidth:2];
            break;
        case 108:
            [MBProgressHUD showMessageWithText:@"已修改画笔为粗笔"];
            [self.drawView setLineWidth:3];
            break;
        case 109:
            [MBProgressHUD showMessageWithText:@"画笔模式"];
            break;
        case 110:
            [MBProgressHUD showMessageWithText:@"鼠标模式"];
            break;
        case 111:
            [MBProgressHUD showMessageWithText:@"下一页"];
            break;
        case 112:
            [MBProgressHUD showMessageWithText:@"上一页"];
            break;
        default:
            break;
    }
}

#pragma mark - UITableViewDelegate UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.peripheralInfos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *resueId = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:resueId];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:resueId];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    CBPeripheral *peripheral = self.peripheralInfos[indexPath.row];
    cell.textLabel.text = peripheral.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // 点击设备进行连接操作
    CBPeripheral *peripheral = self.peripheralInfos[indexPath.row];
    [[ZXYBSdk instance] connect:peripheral];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

#pragma mark - lazy
- (NSMutableArray *)peripheralInfos {
    if (!_peripheralInfos) {
        _peripheralInfos = [NSMutableArray array];
    }
    return _peripheralInfos;
}

@end
