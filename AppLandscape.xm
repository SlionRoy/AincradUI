#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
// Separate opt-in injection target. SpringBoard tweaks remain untouched.
static BOOL AIPSelected(void) {
    static BOOL initialized = NO;
    static BOOL selected = NO;
    if (initialized) return selected;
    initialized = YES;
    NSString *bundle = [NSBundle mainBundle].bundleIdentifier;
    if (!bundle || [bundle hasPrefix:@"com.apple."] || [bundle hasPrefix:@"com.aincrad."]) return NO;
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.aincrad.ui.plist"];
    NSArray *ids = p[@"AppLandscapeIDs"];
    selected = [p[@"Enabled"] boolValue] && [ids isKindOfClass:NSArray.class] && [ids containsObject:bundle];
    return selected;
}
%hook UIViewController
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return AIPSelected() ? UIInterfaceOrientationMaskLandscape : %orig;
}
- (BOOL)shouldAutorotate {
    return AIPSelected() ? YES : %orig;
}
%end
%hook UIApplication
- (UIInterfaceOrientationMask)supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return AIPSelected() ? UIInterfaceOrientationMaskLandscape : %orig;
}
%end
