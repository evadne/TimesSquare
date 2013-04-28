#import "TSQCalendarTableView.h"

@implementation TSQCalendarTableView

- (void) layoutSubviews {
	
	[self.delegate calendarTableViewWillLayoutSubviews:self];
	[super layoutSubviews];
	[self.delegate calendarTableViewDidLayoutSubviews:self];
	
}

@end
