#import <Foundation/Foundation.h>

typedef NSDateFormatter * (^TSQDateFormatterCreator)(void);

@interface NSCalendar (TSQAdditions)

- (NSDateFormatter *) dateFormatterForKey:(NSString *)key withCreator:(TSQDateFormatterCreator)creator;

- (NSMutableDictionary *) dateFormatters;

@end
