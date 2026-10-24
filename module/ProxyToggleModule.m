#import <UIKit/UIKit.h>
#import "proxyctl.h"

@interface CCUIToggleModule : NSObject
- (BOOL)isSelected;
- (void)setSelected:(BOOL)selected;
- (void)refreshState;
@end

@interface ProxyToggleModule : CCUIToggleModule
@end

@implementation ProxyToggleModule

- (UIImage *)iconGlyph {
	UIImage *i = [UIImage imageNamed:@"Icon" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil];
	return i ?: [UIImage systemImageNamed:@"network"];
}

- (UIColor *)selectedColor {
	return [UIColor colorWithRed:48/255.0 green:209/255.0 blue:88/255.0 alpha:1]; // the green of the app icon
}

- (BOOL)isSelected {
	return [proxyctl("status", NULL, NULL) isEqual:@"1"];
}

- (void)setSelected:(BOOL)selected {
	proxyctl(selected ? "on" : "off", NULL, NULL);
	[super setSelected:selected];
	[self refreshState];
}

@end
