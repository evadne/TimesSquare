//
//  TSQCalendarRowCell.m
//  TimesSquare
//
//  Created by Jim Puls on 11/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "TSQCalendarRowCell.h"
#import "TSQCalendarView.h"
#import "TSQTextButton.h"
#import "NSCalendar+TSQAdditions.h"


@interface TSQCalendarRowCell ()

@property (nonatomic, strong) NSArray *dayButtons;
@property (nonatomic, strong) NSArray *notThisMonthButtons;
@property (nonatomic, strong) UIButton *todayButton;
@property (nonatomic, strong) UIButton *selectedButton;

@property (nonatomic, assign) NSInteger indexOfTodayButton;
@property (nonatomic, assign) NSInteger indexOfSelectedButton;

@property (nonatomic, strong) NSDateComponents *todayDateComponents;
@property (nonatomic) NSInteger monthOfBeginningDate;

- (NSDateFormatter *) dayFormatter;
- (NSDateFormatter *) accessibilityFormatter;

@end


@implementation TSQCalendarRowCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
    CGFloat onePixel = 1.0f / [UIScreen mainScreen].scale;
    self.backgroundColor = [UIColor colorWithRed:0.84f green:0.85f blue:0.86f alpha:1.0f];
    self.shadowOffset = (CGSize){ 0.0f, onePixel };
    self.columnSpacing = onePixel;
    self.textLabel.textColor = [UIColor colorWithRed:0.47f green:0.5f blue:0.53f alpha:1.0f];
		self.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	return self;
}

- (void) setHighlighted:(BOOL)selected animated:(BOOL)animated {
	//	NO OP
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
	//	NO OP
}

- (void) configureButton:(UIButton *)button {
	button.backgroundColor = self.backgroundColor;
	button.titleLabel.font = [UIFont boldSystemFontOfSize:19.f];
	button.titleLabel.shadowOffset = self.shadowOffset;
	button.titleLabel.backgroundColor = self.backgroundColor;
	button.titleLabel.textAlignment = NSTextAlignmentCenter;
	button.adjustsImageWhenDisabled = NO;
	[button setTitleColor:self.textLabel.textColor forState:UIControlStateNormal];
	[button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)createDayButtons {

	NSMutableArray *dayButtons = [NSMutableArray arrayWithCapacity:self.daysInWeek];
	for (NSUInteger index = 0; index < self.daysInWeek; index++) {
			UIButton *button = [[TSQTextButton alloc] initWithFrame:self.contentView.bounds];
			[button addTarget:self action:@selector(dateButtonPressed:) forControlEvents:UIControlEventTouchDown];
			[dayButtons addObject:button];
			[self.contentView addSubview:button];
			[self configureButton:button];
			[button setTitleColor:[self.textLabel.textColor colorWithAlphaComponent:0.5f] forState:UIControlStateDisabled];
	}
	self.dayButtons = dayButtons;
	
}

- (void) createNotThisMonthButtons {

	NSMutableArray *notThisMonthButtons = [NSMutableArray arrayWithCapacity:self.daysInWeek];
	for (NSUInteger index = 0; index < self.daysInWeek; index++) {
			UIButton *button = [[TSQTextButton alloc] initWithFrame:self.contentView.bounds];
			[notThisMonthButtons addObject:button];
			[self.contentView addSubview:button];
			[self configureButton:button];

			button.enabled = NO;
			UIColor *backgroundPattern = [UIColor colorWithPatternImage:[self notThisMonthBackgroundImage]];
			button.backgroundColor = backgroundPattern;
			button.titleLabel.backgroundColor = backgroundPattern;
	}
	self.notThisMonthButtons = notThisMonthButtons;
	
}

- (void) createTodayButton {
	self.todayButton = [[TSQTextButton alloc] initWithFrame:self.contentView.bounds];
	[self.contentView addSubview:self.todayButton];
	[self configureButton:self.todayButton];
	[self.todayButton addTarget:self action:@selector(todayButtonPressed:) forControlEvents:UIControlEventTouchDown];
	
	[self.todayButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.todayButton setBackgroundImage:[self todayBackgroundImage] forState:UIControlStateNormal];
	[self.todayButton setTitleShadowColor:[UIColor colorWithWhite:0.0f alpha:0.75f] forState:UIControlStateNormal];

	self.todayButton.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f / [UIScreen mainScreen].scale);
}

- (void)createSelectedButton;
{
    self.selectedButton = [[TSQTextButton alloc] initWithFrame:self.contentView.bounds];
    [self.contentView addSubview:self.selectedButton];
    [self configureButton:self.selectedButton];
    
    self.selectedButton.enabled = NO;
    [self.selectedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.selectedButton setBackgroundImage:[self selectedBackgroundImage] forState:UIControlStateNormal];
    [self.selectedButton setTitleShadowColor:[UIColor colorWithWhite:0.0f alpha:0.75f] forState:UIControlStateNormal];
    
    self.selectedButton.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f / [UIScreen mainScreen].scale);
    self.indexOfSelectedButton = -1;
}

- (void)setBeginningDate:(NSDate *)date;
{
    _beginningDate = date;
    
    NSDateComponents *offset = [NSDateComponents new];
    offset.day = 1;

    self.todayButton.hidden = YES;
    self.indexOfTodayButton = -1;
    self.selectedButton.hidden = YES;
    self.indexOfSelectedButton = -1;
    
    for (NSUInteger index = 0; index < self.daysInWeek; index++) {
        NSString *title = [[self dayFormatter] stringFromDate:date];
        NSString *accessibilityLabel = [[self accessibilityFormatter] stringFromDate:date];
        [self.dayButtons[index] setTitle:title forState:UIControlStateNormal];
        [self.dayButtons[index] setAccessibilityLabel:accessibilityLabel];
        [self.notThisMonthButtons[index] setTitle:title forState:UIControlStateNormal];
        [self.notThisMonthButtons[index] setAccessibilityLabel:accessibilityLabel];
        
        NSDateComponents *thisDateComponents = [self.calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:date];
        
        [self.dayButtons[index] setHidden:YES];
        [self.notThisMonthButtons[index] setHidden:YES];

        NSInteger thisDayMonth = thisDateComponents.month;
        if (self.monthOfBeginningDate != thisDayMonth) {
            [self.notThisMonthButtons[index] setHidden:NO];
        } else {

            if ([self.todayDateComponents isEqual:thisDateComponents]) {
                self.todayButton.hidden = NO;
                [self.todayButton setTitle:title forState:UIControlStateNormal];
                [self.todayButton setAccessibilityLabel:accessibilityLabel];
                self.indexOfTodayButton = index;
            } else {
                UIButton *button = self.dayButtons[index];
                button.enabled = ![self.calendarView.delegate respondsToSelector:@selector(calendarView:shouldSelectDate:)] || [self.calendarView.delegate calendarView:self.calendarView shouldSelectDate:date];
                button.hidden = NO;
            }
        }

        date = [self.calendar dateByAddingComponents:offset toDate:date options:0];
    }
}

- (void)setBottomRow:(BOOL)bottomRow;
{
    UIImageView *backgroundImageView = (UIImageView *)self.backgroundView;
    if ([backgroundImageView isKindOfClass:[UIImageView class]] && _bottomRow == bottomRow) {
        return;
    }

    _bottomRow = bottomRow;
    
    self.backgroundView = [[UIImageView alloc] initWithImage:self.backgroundImage];
    
    [self setNeedsLayout];
}

- (IBAction)dateButtonPressed:(id)sender;
{
    NSDateComponents *offset = [NSDateComponents new];
    offset.day = [self.dayButtons indexOfObject:sender];
    NSDate *selectedDate = [self.calendar dateByAddingComponents:offset toDate:self.beginningDate options:0];
    self.calendarView.selectedDate = selectedDate;
}

- (IBAction)todayButtonPressed:(id)sender;
{
    NSDateComponents *offset = [NSDateComponents new];
    offset.day = self.indexOfTodayButton;
    NSDate *selectedDate = [self.calendar dateByAddingComponents:offset toDate:self.beginningDate options:0];
    self.calendarView.selectedDate = selectedDate;
}

- (NSUInteger) daysInWeek {
	return [self.calendar maximumRangeOfUnit:NSWeekdayCalendarUnit].length;
}

- (void) layoutSubviews {

    if (!self.dayButtons) {
        [self createDayButtons];
        [self createNotThisMonthButtons];
        [self createTodayButton];
        [self createSelectedButton];
    }
    
    if (!self.backgroundView) {
        [self setBottomRow:NO];
    }
    
    [super layoutSubviews];
  
		NSUInteger count = 0;
		[self.calendarView getColumnRects:NULL forBounds:self.bounds count:&count];
		
		CGRect *rects = malloc(count * sizeof(CGRect));
		[self.calendarView getColumnRects:rects forBounds:self.bounds count:&count];
		for (NSUInteger i = 0; i < count; i++) {
			[self layoutViewsForColumnAtIndex:i inRect:rects[i]];
		}
		
    self.backgroundView.frame = self.bounds;
}

- (void)layoutViewsForColumnAtIndex:(NSUInteger)index inRect:(CGRect)rect;
{
    UIButton *dayButton = self.dayButtons[index];
    UIButton *notThisMonthButton = self.notThisMonthButtons[index];
    
    dayButton.frame = rect;
    notThisMonthButton.frame = rect;

    if (self.indexOfTodayButton == (NSInteger)index) {
        self.todayButton.frame = rect;
    }
    if (self.indexOfSelectedButton == (NSInteger)index) {
        self.selectedButton.frame = rect;
    }
}

- (void)selectColumnForDate:(NSDate *)date;
{
    if (!date && self.indexOfSelectedButton == -1) {
        return;
    }

    NSInteger newIndexOfSelectedButton = -1;
    if (date) {
        NSInteger thisDayMonth = [self.calendar components:NSMonthCalendarUnit fromDate:date].month;
        if (self.monthOfBeginningDate == thisDayMonth) {
            newIndexOfSelectedButton = [self.calendar components:NSDayCalendarUnit fromDate:self.beginningDate toDate:date options:0].day;
            if (newIndexOfSelectedButton >= (NSInteger)self.daysInWeek) {
                newIndexOfSelectedButton = -1;
            }
        }
    }

    self.indexOfSelectedButton = newIndexOfSelectedButton;
    
    if (newIndexOfSelectedButton >= 0) {
        self.selectedButton.hidden = NO;
        [self.selectedButton setTitle:[self.dayButtons[newIndexOfSelectedButton] currentTitle] forState:UIControlStateNormal];
        [self.selectedButton setAccessibilityLabel:[self.dayButtons[newIndexOfSelectedButton] accessibilityLabel]];
    } else {
        self.selectedButton.hidden = YES;
    }
    
    [self setNeedsLayout];
}

- (NSInteger)monthOfBeginningDate;
{
    if (!_monthOfBeginningDate) {
        _monthOfBeginningDate = [self.calendar components:NSMonthCalendarUnit fromDate:self.firstOfMonth].month;
    }
    return _monthOfBeginningDate;
}

- (void) setFirstOfMonth:(NSDate *)firstOfMonth {
	_firstOfMonth = firstOfMonth;
	self.monthOfBeginningDate = 0;
}

- (NSDateComponents *)todayDateComponents;
{
    if (!_todayDateComponents) {
        self.todayDateComponents = [self.calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:[NSDate date]];
    }
    return _todayDateComponents;
}

- (NSDateFormatter *) dayFormatter {
	return [self.calendar dateFormatterForKey:@"cellDay" withCreator:^ {
		NSDateFormatter *formatter = [NSDateFormatter new];
		formatter.calendar = self.calendar;
		formatter.dateFormat = @"d";
		return formatter;
	}];
}

- (NSDateFormatter *) accessibilityFormatter {
	return [self.calendar dateFormatterForKey:@"cellDayAccessibility" withCreator:^{
		NSDateFormatter *formatter = [NSDateFormatter new];
		formatter.calendar = self.calendar;
		formatter.dateStyle = NSDateFormatterLongStyle;
		return formatter;
	}];
}

@end
