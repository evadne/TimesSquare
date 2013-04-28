//
//  TSQCalendarMonthHeaderCell.h
//  TimesSquare
//
//  Created by Jim Puls on 11/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "TSQCalendarView.h"

/** The `TSQCalendarMonthHeaderCell` class displays the month name and day names at the top of a month's worth of weeks.
 
 By default, it lays out the day names in the bottom 20 points, the month name in the remainder of its height, and has a height of 65 points. You'll want to subclass it to change any of those things.
 */
@interface TSQCalendarMonthHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) NSDate *firstOfMonth;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, weak) TSQCalendarView *calendarView;
@property (nonatomic, readonly) CGFloat cellHeight;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic) CGSize shadowOffset;
@property (nonatomic) CGFloat columnSpacing;
@property (nonatomic, strong) NSArray *headerLabels;

@end
