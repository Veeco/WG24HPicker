//
//  WG24HPickerView.h
//
//  Created by Veeco on 5/20/17.
//  Copyright © 2017 Veeco. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WG24HPicker;

@protocol WG24HPickerDelegate <NSObject>

/**
 * 监听确定按钮点击
 * 参数 timeStamps 所选时间的时间戮
 * 参数 description 所选时间描述
 * 参数 picker 自身
 */
- (void)didClickConfirmWithTimeStamps:(NSTimeInterval)timeStamps description:(nonnull NSString *)description inPicker:(nonnull __kindof WG24HPicker *)picker;

@end

@interface WG24HPicker : NSObject

/**
 * 展示界面
 */
- (void)show;

/** 代理 */
@property (nonatomic, weak, nullable) id <WG24HPickerDelegate> delegate;

@end
