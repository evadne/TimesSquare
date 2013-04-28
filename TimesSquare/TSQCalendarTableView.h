#import <UIKit/UIKit.h>

@class TSQCalendarTableView;
@protocol TSQCalendarTableViewDelegate <UITableViewDelegate>

- (void) calendarTableViewWillLayoutSubviews:(TSQCalendarTableView *)calendarTableView;
- (void) calendarTableViewDidLayoutSubviews:(TSQCalendarTableView *)calendarTableView;

@end

@interface TSQCalendarTableView : UITableView

@property (nonatomic, assign) id <TSQCalendarTableViewDelegate> delegate;

@end
