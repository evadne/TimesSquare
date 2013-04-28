#import <objc/runtime.h>
#import "NSCalendar+TSQAdditions.h"

@implementation NSCalendar (TSQAdditions)

- (NSDateFormatter *) dateFormatterForKey:(NSString *)key withCreator:(TSQDateFormatterCreator)creator {
	NSDateFormatter *answer = [self dateFormatters][key];
	if (!answer) {
		answer = creator();
		[self dateFormatters][key] = answer;
	}
	return answer;
}

- (NSMutableDictionary *) dateFormatters {
	const void *key = &key;
	NSMutableDictionary *answer = objc_getAssociatedObject(self, &key);
	if (!answer) {
		answer = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &key, answer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return answer;
}

@end
