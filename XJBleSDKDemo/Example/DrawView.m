//
//  DrawView.m
//  XJBleSDKDemo
//
//  Created by apple on 2020/11/19.
//  Copyright © 2020 CoderYS. All rights reserved.
//

#import "DrawView.h"
#import "DrawBezirPath.h"

@interface DrawView ()

@property (nonatomic,strong)NSMutableArray *paths;

@end

@implementation DrawView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {

        self.lineWidth = 2.0;
        self.lineColor = [UIColor redColor];
    }
    return self;
}

- (NSMutableArray *)paths {
    if (_paths == nil) {
        _paths = [NSMutableArray array];
    }
    return _paths;
}

// 清屏
- (void)cleanScreen {
    [self.paths removeAllObjects];
    
    [self setNeedsDisplay];
}

// 撤下一步
- (void)undo {
    [self.paths removeLastObject];
    
    [self setNeedsDisplay];
}

- (void)setLineColor:(UIColor *)lineColor {
    _lineColor = lineColor;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
}

// 坐标转换
- (CGPoint)convert:(CGFloat)x y:(CGFloat)y {
    CGFloat sx = self.height - x;
    CGFloat sy = y;
    return CGPointMake(sy, sx);
}

// 0 悬停 1 按下 2 移动 3 抬起 4 离开
- (void)setPacket:(XYDataPacket *)packet {
    if (packet.penStatus == 1) {
        
        // CGPoint loc = [self convert:packet.tx y:packet.ty];
        CGPoint loc = CGPointMake(packet.tx, packet.ty);
        
        DrawBezirPath *path = [[DrawBezirPath alloc] init];
        [path moveToPoint:loc];
        
        path.lineWidth = self.lineWidth;
        path.lineColor = self.lineColor;
        
        [self.paths addObject:path];
        
    } else if (packet.penStatus == 2) {
        
        // CGPoint loc = [self convert:packet.tx y:packet.ty];
        CGPoint loc = CGPointMake(packet.tx, packet.ty);
        
        DrawBezirPath *path = [self.paths lastObject];
        
        [path addLineToPoint:loc];
        
        [self setNeedsDisplay];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    CGPoint loc = [touch locationInView:touch.view];
    
    DrawBezirPath *path = [[DrawBezirPath alloc] init];
    
    [path moveToPoint:loc];
    
    path.lineWidth = self.lineWidth;
    path.lineColor = self.lineColor;
    
    [self.paths addObject:path];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    CGPoint loc = [touch locationInView:touch.view];
    
    DrawBezirPath *path = [self.paths lastObject];
    
    [path addLineToPoint:loc];
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    
    for (DrawBezirPath *path in self.paths) {
        
        [path setLineCapStyle:kCGLineCapRound];
        [path setLineJoinStyle:kCGLineJoinRound];
        
        [path.lineColor set];
        [path stroke];
    }
}

@end
