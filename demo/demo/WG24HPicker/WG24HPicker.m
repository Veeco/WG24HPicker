//
// WG24HPickerView.m
//
// Created by Veeco on 5/20/17.
// Copyright © 2017 Veeco. All rights reserved.
//

#import "WG24HPicker.h"

@interface WG24HPicker () <UIPickerViewDataSource, UIPickerViewDelegate>

// 数据源

/** 时数据今天 */
@property (nonatomic, copy) NSArray *hourDataToday;
/** 时数据明天 */
@property (nonatomic, copy) NSArray *hourDataTomorrow;
/** 分数据今天当前时 */
@property (nonatomic, copy) NSArray *minuteDataTodayCurrentHour;
/** 分数据明天当前时 */
@property (nonatomic, copy) NSArray *minuteDataTomorrowCurrentHour;
/** 分数据全时 */
@property (nonatomic, copy) NSArray *minuteDataAll;
/** 第一列数据 */
@property (nonatomic, copy) NSArray *dayData;
/** 第二列数据 */
@property (nonatomic, copy) NSArray *hourData;
/** 第三列数据 */
@property (nonatomic, copy) NSArray *minuteData;

// 展示控件

/** 弹出的背景 */
@property (nonatomic, weak) UIView * bgView;
/** 展示文字 */
@property (nonatomic, weak) UILabel *hintLabel;
/** 时间选择view */
@property (nonatomic, weak) UIPickerView *chooseView;

// 处理数据

/** 第一列(日)当前下标 */
@property (nonatomic, assign) NSInteger dayIndex;
/** 第二列(时)当前下标 */
@property (nonatomic, assign) NSInteger hourIndex;
/** 第三列(分)当前下标 */
@property (nonatomic, assign) NSInteger minuteIndex;
/** 当前所选时 */
@property (nonatomic, assign) NSUInteger currentHour;
/** 当前所选分 */
@property (nonatomic, assign) NSUInteger currentMinute;

@end

@implementation WG24HPicker

#pragma mark - <懒加载>

- (UIView *)bgView {
    if (!_bgView) {
        
        // 背景
        UIView * bgView = [[UIView alloc] init];
        [[UIApplication sharedApplication].keyWindow addSubview: bgView];
        bgView.frame = [UIScreen mainScreen].bounds;
        bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [bgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)]];
        _bgView = bgView;
        
        CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
        CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
        
        // 下方内容view
        UIView *bottomView = [[UIView alloc] init];
        [bgView addSubview:bottomView];
        bottomView.backgroundColor = [UIColor whiteColor];
        
        CGFloat bottomW = screenW;
        CGFloat bottomH = 200;
        CGFloat bottomX = 0;
        CGFloat bottomY = screenH - bottomH;
        
        bottomView.frame = CGRectMake(bottomX, bottomY, bottomW, bottomH);
        
        // 文字部分灰色遮罩
        UIView *grayView = [[UIView alloc] init];
        [bottomView addSubview:grayView];
        grayView.backgroundColor = [UIColor colorWithRed:249 / 255.0 green:249 / 255.0 blue:249 / 255.0 alpha:1.0];
  
        CGFloat grayW = bottomW;
        CGFloat grayH = 40;
        CGFloat grayX = 0;
        CGFloat grayY = 0;
        
        grayView.frame = CGRectMake(grayX, grayY, grayW, grayH);
        
        // 确定按钮
        UILabel *confirm = [[UILabel alloc] init];
        [grayView addSubview:confirm];
        confirm.font = [UIFont systemFontOfSize:17];
        confirm.text = @"确定";
        confirm.textColor = [UIColor colorWithRed:4 / 255.0 green:189 / 255.0 blue:189 / 255.0 alpha:1.0];
        confirm.userInteractionEnabled = YES;
        [confirm addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didClickConfirm)]];
        
        CGFloat confirmW = confirm.font.pointSize * 1.5 * confirm.text.length;
        CGFloat confirmH = grayH;
        CGFloat confirmX = 10;
        CGFloat confirmY = 0;
        
        confirm.frame = CGRectMake(confirmX, confirmY, confirmW, confirmH);
        
        // 取消按钮
        UILabel *cancel = [[UILabel alloc] init];
        [grayView addSubview:cancel];
        cancel.font = confirm.font;
        cancel.textColor = confirm.textColor;
        cancel.text = @"取消";
        cancel.textAlignment = NSTextAlignmentRight;
        cancel.userInteractionEnabled = YES;
        [cancel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)]];
 
        CGFloat cancelW = cancel.font.pointSize * 1.5 * cancel.text.length;
        CGFloat cancelH = confirmH;
        CGFloat cancelX = grayW - cancelW - 10;
        CGFloat cancelY = confirmY;
        
        cancel.frame = CGRectMake(cancelX, cancelY, cancelW, cancelH);
        
        // 提示文字
        UILabel *hintLabel = [[UILabel alloc] init];
        [grayView addSubview:hintLabel];
        hintLabel.textColor = [UIColor colorWithRed:144 / 255.0 green:144 / 255.0 blue:144 / 255.0 alpha:1.0];
        hintLabel.font = [UIFont systemFontOfSize:14];
        self.hintLabel = hintLabel;
        hintLabel.textAlignment = NSTextAlignmentCenter;
        
        CGFloat hintW = CGRectGetMinX(cancel.frame) - CGRectGetMaxX(confirm.frame);
        CGFloat hintH = grayH;
        CGFloat hintCX = grayW / 2;
        CGFloat hintCY = grayH / 2;
        
        hintLabel.bounds = CGRectMake(0, 0, hintW, hintH);
        hintLabel.center = CGPointMake(hintCX, hintCY);
        
        // 选择view
        UIPickerView *chooseView = [[UIPickerView alloc] init];
        [bottomView addSubview:chooseView];
        self.chooseView = chooseView;
        chooseView.dataSource = self;
        chooseView.delegate = self;

        CGFloat chooseW = grayW;
        CGFloat chooseH = bottomH - grayH;
        CGFloat chooseX = 0;
        CGFloat chooseY = CGRectGetMaxY(grayView.frame);
        
        chooseView.frame = CGRectMake(chooseX, chooseY, chooseW, chooseH);
    }
    return _bgView;
}

#pragma mark - <具体数据源>

- (NSArray *)hourDataToday {
    if (!_hourDataToday) {
        
        NSMutableArray *arrM = [NSMutableArray array];
        
        NSDateComponents *dateComponents = [self getTimeDataFromNow:0];
        
        NSUInteger hour = dateComponents.hour;
        
        // 当前时间是59分时, 小时数+1, 因为已经没有分钟可设置了
        NSUInteger minute = dateComponents.minute;
        if (minute == 59) hour += 1;
        
        for (NSUInteger i = hour; i < 24; i++) {
            
            [arrM addObject:@(i)];
        }
        _hourDataToday = arrM;
    }
    return _hourDataToday;
}

- (NSArray *)hourDataTomorrow {
    if (!_hourDataTomorrow) {
        
        NSMutableArray *arrM = [NSMutableArray array];
        
        NSDateComponents *dateComponents = [self getTimeDataFromNow:0];
        
        NSUInteger hour = dateComponents.hour;
        
        for (NSUInteger i = 0; i <= hour; i++) {
            
            [arrM addObject:@(i)];
        }
        _hourDataTomorrow = arrM;
    }
    return _hourDataTomorrow;
}

- (NSArray *)minuteDataTodayCurrentHour {
    if (!_minuteDataTodayCurrentHour) {
        
        NSDateComponents *dateComponents = [self getTimeDataFromNow:0];
        
        NSUInteger minute = dateComponents.minute;
        
        // 59分时, 为可全选区
        if (minute == 59) _minuteDataTodayCurrentHour = self.minuteDataAll;
        
        else {
            
            NSMutableArray *arrM = [NSMutableArray array];
            
            for (NSUInteger i = minute + 1; i < 60; i++) {
                
                [arrM addObject:@(i)];
            }
            _minuteDataTodayCurrentHour = arrM;
        }
    }
    return _minuteDataTodayCurrentHour;
}

- (NSArray *)minuteDataTomorrowCurrentHour {
    if (!_minuteDataTomorrowCurrentHour) {
        
        NSMutableArray *arrM = [NSMutableArray array];
        
        NSDateComponents *dateComponents = [self getTimeDataFromNow:0];
        
        NSUInteger minute = dateComponents.minute;
        
        for (NSUInteger i = 0; i <= minute; i++) {
            
            [arrM addObject:@(i)];
        }
        _minuteDataTomorrowCurrentHour = arrM;
    }
    return _minuteDataTomorrowCurrentHour;
}

- (NSArray *)minuteDataAll {
    if (!_minuteDataAll) {
        
        NSMutableArray *arrM = [NSMutableArray array];
        
        for (NSUInteger i = 0; i < 60; i++) {
            
            [arrM addObject:@(i)];
        }
        _minuteDataAll = arrM;
    }
    return _minuteDataAll;
}

#pragma mark - <抽象数据源>

- (NSArray *)dayData {
    if (!_dayData) {
        
        _dayData = @[@"今天", @"明天"];
    }
    return _dayData;
}

- (NSArray *)hourData {
    
    if (self.dayIndex == 0) {
        
        _hourData = self.hourDataToday;
    }
    else {
        
        _hourData = self.hourDataTomorrow;
    }
    return _hourData;
}

- (NSArray *)minuteData {
    
    if (self.dayIndex == 0) {
        
        if (self.hourIndex == 0) {
            
            _minuteData = self.minuteDataTodayCurrentHour;
        }
        else {
            
            _minuteData = self.minuteDataAll;
        }
    }
    else {
        
        if (self.hourIndex == self.hourData.count - 1) {
            
            _minuteData = self.minuteDataTomorrowCurrentHour;
        }
        else {
            
            _minuteData = self.minuteDataAll;
        }
    }
    return _minuteData;
}

#pragma mark - <主体逻辑>

/**
 * 展示界面
 */
- (void)show {
    
    self.bgView.hidden = NO;
    
    // 设置默认滚动
    [self initCurrent];
}

/**
 * 隐藏控件
 */
- (void)hide {

    self.bgView.hidden = YES;
    
    // 隐藏时清空一部分数据源, 以待刷新数据
    self.hourDataToday = nil;
    self.hourDataTomorrow = nil;
    self.minuteDataTodayCurrentHour = nil;
    self.minuteDataTomorrowCurrentHour = nil;
}

/**
 * 设置默认滚动
 * 此处设置为默认滚动到5分钟后
 */
- (void)initCurrent {
    
    // 1. 获取目标时间(5分钟后)的日, 时, 分
    NSDateComponents *dateComponentAfter = [self getTimeDataFromNow:60 * 5];
    
    NSInteger dayAfter = [dateComponentAfter day];
    NSInteger hourAfter = [dateComponentAfter hour];
    NSInteger minuteAfter = [dateComponentAfter minute];
    
    // 1.1 获取当前的日
    NSDateComponents *dateComponentNow = [self getTimeDataFromNow:0];
    NSInteger dayNow = [dateComponentNow day];
    
    // 2. 确定第一列下标
    NSUInteger dayIndex = 0;
    if (dayAfter != dayNow) dayIndex = 1;
    
    // 2.1 滚动第一列
    [self.chooseView selectRow:dayIndex inComponent:0 animated:YES];
    [self pickerView:self.chooseView didSelectRow:dayIndex inComponent:0];
    
    // 3. 确定第二列下标
    __block NSUInteger hourIndex = 0;
    [self.hourData enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.integerValue == hourAfter) {
            
            hourIndex = idx;
            *stop = YES;
        }
    }];
    
    // 3.1 滚动第二列
    [self.chooseView selectRow:hourIndex inComponent:1 animated:YES];
    [self pickerView:self.chooseView didSelectRow:hourIndex inComponent:1];
    
    // 4. 确定第三列下标
    __block NSUInteger minuteIndex = 0;
    [self.minuteData enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.integerValue == minuteAfter) {
            
            minuteIndex = idx;
            *stop = YES;
        }
    }];
    
    // 4.1 滚动第三列
    [self.chooseView selectRow:minuteIndex inComponent:2 animated:YES];
    [self pickerView:self.chooseView didSelectRow:minuteIndex inComponent:2];
}

/**
 * 获取日时分秒信息
 * offset 想获取的时间点距离现在的偏差值
 * 返回 日时分秒信息
 */
- (NSDateComponents *)getTimeDataFromNow:(NSTimeInterval)offset {
    
    NSDate *target = [NSDate dateWithTimeIntervalSinceNow:offset];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSCalendarUnit unitFlags = NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    return [calendar components:unitFlags fromDate:target];
}

/**
 * 监听确定按钮点击
 */
- (void)didClickConfirm {
    
    // 计算所选时间的时间戮
    NSTimeInterval timeStamps = [self calculateTimeStamps];
    
    if ([self.delegate respondsToSelector:@selector(didClickConfirmWithTimeStamps:description:inPicker:)]) {
        [self.delegate didClickConfirmWithTimeStamps:timeStamps description:self.hintLabel.text inPicker:self];
    }
    // 隐藏当前选择控件
    [self hide];
}

/**
 * 计算所选时间的时间戮
 * 返回 时间戮
 */
- (NSTimeInterval)calculateTimeStamps {

    // 1. 获取当前时间点
    NSDateComponents *now = [self getTimeDataFromNow:0];
    
    NSInteger secondNow = now.second;
    NSInteger minuteNow = now.minute;
    NSInteger hourNow = now.hour;
    
    // 1.1 折算成秒
    NSTimeInterval secondTotolNow = secondNow + minuteNow * 60 + hourNow * 60 * 60;
    
    // 2. 将获取所选时间点折算成秒
    NSTimeInterval secondTotolAfter = self.currentMinute * 60 + self.currentHour * 60 * 60;
    
    // 3. 求差
    if (secondTotolAfter <= secondTotolNow) {
        
        secondTotolAfter += 24 * 60 * 60;
    }
    NSTimeInterval offset = secondTotolAfter - secondTotolNow;
    
    // 4. 根据差值返回时间戮
    return [NSDate dateWithTimeIntervalSinceNow:offset].timeIntervalSince1970;
}

- (void)dealloc {

    // 善后
    [self.bgView removeFromSuperview];
}

#pragma mark - <UIPickerViewDatasource>

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    if (component == 0) {
        
        return self.dayData.count;
    }
    else if (component == 1) {
        
        return self.hourData.count;
    }
    else {
        
        return self.minuteData.count;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    if (component == 0) {
        
        return self.dayData[row];
    }
    else if (component == 1) {
        
        return [NSString stringWithFormat:@"%02zd时", [self.hourData[row] integerValue]];
    }
    else {
        
        return [NSString stringWithFormat:@"%02zd分", [self.minuteData[row] integerValue]];
    }
}

#pragma mark - <UIPickerViewDelegate>

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    if (component == 0) {
        
        // 记录当前日的下标, 非常重要
        self.dayIndex = row;
        
        // 刷新时列
        [pickerView reloadComponent:1];
        
        // 递规
        if (self.hourIndex >= self.hourData.count) {
            self.hourIndex = self.hourData.count - 1;
        }
        [self pickerView:pickerView didSelectRow:self.hourIndex inComponent:1];
        
        return;
    }
    else if (component == 1) {
        
        // 记录当前时的下标, 非常重要
        self.hourIndex = row;
        
        // 刷新分列
        [pickerView reloadComponent:2];
        
        // 递规
        if (self.minuteIndex >= self.minuteData.count) {
            self.minuteIndex = self.minuteData.count - 1;
        }
        [self pickerView:pickerView didSelectRow:self.minuteIndex inComponent:2];
        
        return;
    }
    else if (component == 2) {
        
        // 记录当前时的下标, 非常重要
        self.minuteIndex = row;
    }
    
    NSString *currentDay = self.dayData[self.dayIndex];
    self.currentHour = [self.hourData[self.hourIndex] integerValue];
    self.currentMinute = [self.minuteData[self.minuteIndex] integerValue];
    
    self.hintLabel.text = [NSString stringWithFormat:@"%@%02zd时%02zd分", currentDay, self.currentHour, self.currentMinute];
}

@end
