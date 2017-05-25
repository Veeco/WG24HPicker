//
//  ViewController.m
//  demo
//
//  Created by Veeco on 5/20/17.
//  Copyright © 2017 Veeco. All rights reserved.
//

#import "ViewController.h"
#import "WG24HPicker.h"

@interface ViewController () <WG24HPickerDelegate>

/** picker */
@property (nonatomic, strong) WG24HPicker *picker;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化 + 设置代理
    self.picker = [[WG24HPicker alloc] init];
    self.picker.delegate = self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    // 直接展示
    [self.picker show];
}

#pragma mark - <WG24HPickerDelegate>

/**
 * 监听确定按钮点击
 * 参数 timeStamps 所选时间的时间戮
 * 参数 description 所选时间描述
 * 参数 picker 自身
 */
- (void)didClickConfirmWithTimeStamps:(NSTimeInterval)timeStamps description:(nonnull NSString *)description inPicker:(__kindof WG24HPicker *)picker {
    
    NSLog(@"timeStamps = %f, description = %@", timeStamps, description);
}

@end

