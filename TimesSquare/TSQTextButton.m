#import "TSQTextButton.h"

@implementation TSQTextButton

- (CGRect) titleRectForContentRect:(CGRect)contentRect {
	//	Avoid adjusting label bounds here.
	return contentRect;
}

@end
