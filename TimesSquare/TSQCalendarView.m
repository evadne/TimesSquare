//
//  TSQCalendarState.m
//  TimesSquare
//
//  Created by Jim Puls on 11/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "TSQCalendarView.h"
#import "TSQCalendarMonthHeaderView.h"
#import "TSQCalendarRowCell.h"
#import "TSQCalendarTableView.h"

static NSString * const TSQCalendarCellReuseIdentifier = @"TSQCalendarCell";
static NSString * const TSQCalendarHeaderViewReuseIdentifier = @"TSQCalendarHeaderView";

@interface TSQCalendarView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, readonly, strong) UITableView *tableView;

@end

@implementation TSQCalendarView

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    self = [super initWithCoder:aDecoder];
    if (self) {
			[self _TSQCalendarView_commonInit];
		}
    return self;
}

- (id)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
			[self _TSQCalendarView_commonInit];
		}
    return self;
}

- (void)_TSQCalendarView_commonInit;
{
    _tableView = [[TSQCalendarTableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
		_tableView.rowHeight = 46.0f;
		_tableView.sectionHeaderHeight = 65.0f;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
		[_tableView registerClass:[self rowCellClass] forCellReuseIdentifier:TSQCalendarCellReuseIdentifier];
		[_tableView registerClass:[self headerViewClass] forHeaderFooterViewReuseIdentifier:TSQCalendarHeaderViewReuseIdentifier];
		
    [self addSubview:_tableView];
}

- (Class) headerViewClass {
	return [TSQCalendarMonthHeaderView class];
}

- (Class) rowCellClass {
	return [TSQCalendarRowCell class];
}

- (void) dealloc {
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
}

- (NSCalendar *)calendar;
{
    if (!_calendar) {
			_calendar = [NSCalendar currentCalendar];
    }
    return _calendar;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor;
{
    [super setBackgroundColor:backgroundColor];
    [self.tableView setBackgroundColor:backgroundColor];
}

- (void)setPinsHeaderToTop:(BOOL)pinsHeaderToTop;
{
    _pinsHeaderToTop = pinsHeaderToTop;
    [self setNeedsLayout];
}

- (void)setFirstDate:(NSDate *)firstDate;
{
    // clamp to the beginning of its month
    _firstDate = [self clampDate:firstDate toComponents:NSMonthCalendarUnit|NSYearCalendarUnit];
}

- (void)setLastDate:(NSDate *)lastDate;
{
    // clamp to the end of its month
    NSDate *firstOfMonth = [self clampDate:lastDate toComponents:NSMonthCalendarUnit|NSYearCalendarUnit];
    
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    offsetComponents.month = 1;
    offsetComponents.day = -1;
    _lastDate = [self.calendar dateByAddingComponents:offsetComponents toDate:firstOfMonth options:0];
}

- (void)setSelectedDate:(NSDate *)newSelectedDate;
{
    // clamp to beginning of its day
    NSDate *startOfDay = [self clampDate:newSelectedDate toComponents:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit];
    
    if ([self.delegate respondsToSelector:@selector(calendarView:shouldSelectDate:)] && ![self.delegate calendarView:self shouldSelectDate:startOfDay]) {
        return;
    }
    
    [[self cellForRowAtDate:_selectedDate] selectColumnForDate:nil];
    [[self cellForRowAtDate:startOfDay] selectColumnForDate:startOfDay];
    NSIndexPath *newIndexPath = [self indexPathForRowAtDate:startOfDay];
    CGRect newIndexPathRect = [self.tableView rectForRowAtIndexPath:newIndexPath];
    CGRect scrollBounds = self.tableView.bounds;
    
    if (self.pagingEnabled) {
        CGRect sectionRect = [self.tableView rectForSection:newIndexPath.section];
        [self.tableView setContentOffset:sectionRect.origin animated:YES];
    } else {
        if (CGRectGetMinY(scrollBounds) > CGRectGetMinY(newIndexPathRect)) {
            [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else if (CGRectGetMaxY(scrollBounds) < CGRectGetMaxY(newIndexPathRect)) {
            [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
    
    _selectedDate = startOfDay;
    
    if ([self.delegate respondsToSelector:@selector(calendarView:didSelectDate:)]) {
        [self.delegate calendarView:self didSelectDate:startOfDay];
    }
}

#pragma mark Calendar calculations

- (NSDate *)firstOfMonthForSection:(NSInteger)section;
{
	NSDateComponents *offset = [NSDateComponents new];
	offset.month = section;
	return [self.calendar dateByAddingComponents:offset toDate:self.firstDate options:0];
}

- (TSQCalendarRowCell *)cellForRowAtDate:(NSDate *)date;
{
	return (TSQCalendarRowCell *)[self.tableView cellForRowAtIndexPath:[self indexPathForRowAtDate:date]];
}

- (NSIndexPath *)indexPathForRowAtDate:(NSDate *)date {
	
	if (!date) {
		return nil;
	}

	NSInteger section = [self.calendar components:NSMonthCalendarUnit fromDate:self.firstDate toDate:date options:0].month;
	NSDate *firstOfMonth = [self firstOfMonthForSection:section];
	NSInteger firstWeek = [self.calendar components:NSWeekOfYearCalendarUnit fromDate:firstOfMonth].weekOfYear;
	NSInteger targetWeek = [self.calendar components:NSWeekOfYearCalendarUnit fromDate:date].weekOfYear;
	if (targetWeek < firstWeek) {
		targetWeek = [self.calendar maximumRangeOfUnit:NSWeekOfYearCalendarUnit].length;
	}
	return [NSIndexPath indexPathForRow:(targetWeek - firstWeek) inSection:section];
}

#pragma mark UIView

- (void) layoutSubviews {
	self.tableView.frame = self.bounds;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 1 + [self.calendar components:NSMonthCalendarUnit fromDate:self.firstDate toDate:self.lastDate options:0].month;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
		return 1 + [self.calendar components:NSWeekOfYearCalendarUnit fromDate:[self firstOfMonthForSection:section] toDate:[self firstOfMonthForSection:section + 1] options:0].weekOfYear;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

	TSQCalendarMonthHeaderView *headerCell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:TSQCalendarHeaderViewReuseIdentifier];
	NSCParameterAssert(headerCell);
	headerCell.calendar = self.calendar;
	headerCell.calendarView = self;
	return headerCell;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	TSQCalendarRowCell *cell = [tableView dequeueReusableCellWithIdentifier:TSQCalendarCellReuseIdentifier];
	NSCParameterAssert(cell);
	cell.backgroundColor = self.backgroundColor;
	cell.calendar = self.calendar;
	cell.calendarView = self;
	return cell;
}

#pragma mark UITableViewDelegate

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(TSQCalendarMonthHeaderView *)view forSection:(NSInteger)section {
	
	NSCParameterAssert([view isKindOfClass:[TSQCalendarMonthHeaderView class]]);
	view.firstOfMonth = [self firstOfMonthForSection:section];

}

- (void)tableView:(UITableView *)tableView willDisplayCell:(TSQCalendarRowCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSCParameterAssert([cell isKindOfClass:[TSQCalendarRowCell class]]);
	NSDate *firstOfMonth = [self firstOfMonthForSection:indexPath.section];
	cell.firstOfMonth = firstOfMonth;
	
	NSInteger ordinalityOfFirstDay = [self.calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSWeekCalendarUnit forDate:firstOfMonth];
	NSDateComponents *dateComponents = [NSDateComponents new];
	dateComponents.day = 1 - ordinalityOfFirstDay;
	dateComponents.week = indexPath.row;
	cell.beginningDate = [self.calendar dateByAddingComponents:dateComponents toDate:firstOfMonth options:0];
	[cell selectColumnForDate:self.selectedDate];
	
	BOOL isBottomRow = (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - (self.pinsHeaderToTop ? 0 : 1));
	cell.bottomRow  = isBottomRow;
	
	[cell setNeedsLayout];
	
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset;
{
    if (self.pagingEnabled) {
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:*targetContentOffset];
        // If the target offset is at the third row or later, target the next month; otherwise, target the beginning of this month.
        NSInteger section = indexPath.section;
        if (indexPath.row > 2) {
            section++;
        }
        CGRect sectionRect = [self.tableView rectForSection:section];
        *targetContentOffset = sectionRect.origin;
    }
}

- (NSDate *)clampDate:(NSDate *)date toComponents:(NSUInteger)unitFlags
{
    NSDateComponents *components = [self.calendar components:unitFlags fromDate:date];
    return [self.calendar dateFromComponents:components];
}

- (void) getColumnRects:(CGRect *)rects forBounds:(CGRect)bounds count:(NSUInteger *)outCount {
	
	NSUInteger daysInWeek = [self.calendar maximumRangeOfUnit:NSWeekdayCalendarUnit].length;
	
	if (outCount)
		*outCount = daysInWeek;
	
	if (!rects)
		return;
	
	CGFloat onePixel = 1.0f / [UIScreen mainScreen].scale;
	
	NSString *languageCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
	NSLocaleLanguageDirection layoutDirection = [NSLocale characterDirectionForLanguage:languageCode];
	BOOL rightToLeft = (layoutDirection == NSLocaleLanguageDirectionRightToLeft);
	
	CGFloat columnSpacing = onePixel;
	CGFloat increment = roundf((CGRectGetWidth(bounds) - (daysInWeek - 1) * columnSpacing) / daysInWeek);
	CGFloat __block start = 0.0f;
	CGFloat extraSpace = (CGRectGetWidth(bounds) - (daysInWeek - 1) * columnSpacing) - (increment * daysInWeek);
	
	NSInteger columnsWithExtraSpace = (NSInteger)fabsf(extraSpace / columnSpacing);
	NSInteger columnsOnLeftWithExtraSpace = columnsWithExtraSpace / 2;
	NSInteger columnsOnRightWithExtraSpace = columnsWithExtraSpace - columnsOnLeftWithExtraSpace;
    
	for (NSUInteger index = 0; index < daysInWeek; index++) {
		
		CGFloat width = increment;
		if (index < columnsOnLeftWithExtraSpace || index >= daysInWeek - columnsOnRightWithExtraSpace) {
			width += (extraSpace / columnsWithExtraSpace);
		}
    
		NSUInteger displayIndex = rightToLeft ? (daysInWeek - index - 1) : index;
		NSCParameterAssert(displayIndex < daysInWeek);
		
		rects[displayIndex] = (CGRect) {
			start,
			bounds.origin.y,
			width,
			bounds.size.height
		};
		
		start += width + columnSpacing;
		
	}
}

- (void) calendarTableViewWillLayoutSubviews:(TSQCalendarTableView *)calendarTableView {
	
	//	NO OP
	//	This is a hook for precomputation and infinite scrolling
	
}

- (void) calendarTableViewDidLayoutSubviews:(TSQCalendarTableView *)calendarTableView {
	
	//	Push the section headers back up into the space they claimed earlier
	//	so they do not stick on the top
	//	unless we want to pin
	
	if (self.pinsHeaderToTop)
		return;
	
	for (NSUInteger i = 0; i < calendarTableView.numberOfSections; i++) {
		CGRect sectionRect = [calendarTableView rectForSection:i];
		if (CGRectIntersectsRect(calendarTableView.frame, [calendarTableView.superview convertRect:sectionRect fromView:calendarTableView])) {
			UITableViewHeaderFooterView *headerView = [calendarTableView headerViewForSection:i];
			headerView.frame = (CGRect){
				sectionRect.origin,
				headerView.frame.size
			};
		}
	}
	
}

@end
