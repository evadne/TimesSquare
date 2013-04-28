//
//  TSQCalendarMonthHeaderCell.m
//  TimesSquare
//
//  Created by Jim Puls on 11/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "TSQCalendarMonthHeaderView.h"
#import "NSCalendar+TSQAdditions.h"


static const CGFloat TSQCalendarMonthHeaderViewMonthsHeight = 20.f;

@interface TSQCalendarMonthHeaderView ()

- (NSDateFormatter *) monthDateFormatter;
- (NSDateFormatter *) monthWeekdayFormatter;

@end

@implementation TSQCalendarMonthHeaderView

- (id) initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithReuseIdentifier:reuseIdentifier];
	if (self) {
		self.contentView.backgroundColor = [UIColor whiteColor];
		self.backgroundView = nil;
	}
	return self;
}

- (void) setCalendar:(NSCalendar *)calendar {
	
	if (_calendar == calendar)
		return;
	
	for (UIView *headerLabel in self.headerLabels)
		[headerLabel removeFromSuperview];
	
	_calendar = calendar;
	
	NSDate *referenceDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
	NSDateComponents *offset = [NSDateComponents new];
	offset.day = 1;
	NSMutableArray *headerLabels = [NSMutableArray arrayWithCapacity:self.daysInWeek];
	
	for (NSUInteger index = 0; index < self.daysInWeek; index++) {
		NSInteger ordinality = [self.calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSWeekCalendarUnit forDate:referenceDate];
		UILabel *label = [[UILabel alloc] initWithFrame:self.frame];
		label.textAlignment = NSTextAlignmentCenter;
		label.text = [[self monthWeekdayFormatter] stringFromDate:referenceDate];
		label.font = [UIFont boldSystemFontOfSize:12.f];
		label.backgroundColor = self.contentView.backgroundColor;
		label.textColor = self.textColor;
		label.shadowColor = [UIColor whiteColor];
		label.shadowOffset = self.shadowOffset;
		headerLabels[ordinality - 1] = label;
		[self.contentView addSubview:label];
		
		referenceDate = [self.calendar dateByAddingComponents:offset toDate:referenceDate options:0];
	}
    
	self.headerLabels = headerLabels;
	self.textLabel.textAlignment = NSTextAlignmentCenter;
	self.textLabel.textColor = self.textColor;
	self.textLabel.shadowColor = [UIColor whiteColor];
	self.textLabel.shadowOffset = self.shadowOffset;
	
	[self setNeedsLayout];
	
}

- (NSUInteger) daysInWeek {
	return [self.calendar maximumRangeOfUnit:NSWeekdayCalendarUnit].length;
}

- (void) layoutSubviews {
	
	[super layoutSubviews];
	
	if (!self.calendar)
		return;
	
	CGRect bounds = self.bounds;
	bounds.origin.y = CGRectGetHeight(bounds) - TSQCalendarMonthHeaderViewMonthsHeight;
	bounds.size.height = TSQCalendarMonthHeaderViewMonthsHeight;
	
	NSCParameterAssert(self.calendar);
	NSCParameterAssert(self.headerLabels);
	
	NSUInteger count = 0;
	[self.calendarView getColumnRects:NULL forBounds:bounds count:&count];
	CGRect *rects = malloc(count * sizeof(CGRect));
	[self.calendarView getColumnRects:rects forBounds:bounds count:&count];
	for (NSUInteger i = 0; i < count; i++) {
		UILabel *label = self.headerLabels[i];
		CGRect labelFrame = rects[i];
		labelFrame.size.height = TSQCalendarMonthHeaderViewMonthsHeight;
		labelFrame.origin.y = self.bounds.size.height - TSQCalendarMonthHeaderViewMonthsHeight;
		label.frame = labelFrame;
	}
	free(rects);

}

- (void) setFirstOfMonth:(NSDate *)firstOfMonth {
	
	_firstOfMonth = firstOfMonth;
	
	self.textLabel.text = [NSString stringWithFormat:@"%@ %i", [self monthDateFormatter].monthSymbols[([self.calendar components:NSMonthCalendarUnit fromDate:firstOfMonth]).month - 1], [self.calendar components:NSYearCalendarUnit fromDate:firstOfMonth].year];
	self.accessibilityLabel = self.textLabel.text;
	
}

- (void) setBackgroundColor:(UIColor *)backgroundColor {
	[super setBackgroundColor:backgroundColor];
	for (UILabel *label in self.headerLabels) {
		label.backgroundColor = backgroundColor;
	}
}

- (NSDateFormatter *) monthDateFormatter {
	return [self.calendar dateFormatterForKey:@"headerMonth" withCreator:^ {
		NSDateFormatter *formatter = [NSDateFormatter new];
		formatter.calendar = self.calendar;
		formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"yyyyLLLL" options:0 locale:[NSLocale currentLocale]];
		return formatter;
	}];
}

- (NSDateFormatter *) monthWeekdayFormatter {
	return [self.calendar dateFormatterForKey:@"monthWeekday" withCreator:^{
		NSDateFormatter *formatter = [NSDateFormatter new];
		formatter.calendar = self.calendar;
		formatter.dateFormat = @"cccccc";
		return formatter;
	}];
}

@end
