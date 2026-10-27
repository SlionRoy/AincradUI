#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

static BOOL gEnabled = NO;
static BOOL gHideDock = YES;
static BOOL gLandscape = NO;
static NSString * const kPrefsPath = @"/var/mobile/Library/Preferences/com.aincrad.ui.plist";
static void LoadPrefs(void) {
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];
    gEnabled = [p[@"Enabled"] boolValue];
    gHideDock = p[@"HideDock"] ? [p[@"HideDock"] boolValue] : YES;
    gLandscape = [p[@"Landscape"] boolValue];
}
static void Changed(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) { LoadPrefs(); }
static BOOL ShouldHide(void) { return gEnabled && gHideDock; }
static BOOL ShouldRotate(void) { return gEnabled && gLandscape; }

%hook SBIconController
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return ShouldRotate() ? UIInterfaceOrientationMaskAllButUpsideDown : %orig;
}
- (BOOL)shouldAutorotate {
    return ShouldRotate() ? YES : %orig;
}
%end

%hook SBRootFolderController
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return ShouldRotate() ? UIInterfaceOrientationMaskAllButUpsideDown : %orig;
}
- (BOOL)shouldAutorotate {
    return ShouldRotate() ? YES : %orig;
}
%end

// Dock containers: try both commonly observed SpringBoard classes.
// This remains unverified against iOS 16.7.16 internals.
%hook SBDockView
- (void)didMoveToWindow {
    %orig;
    [(UIView *)self setHidden:ShouldHide()];
}
- (void)layoutSubviews {
    %orig;
    [(UIView *)self setHidden:ShouldHide()];
}
%end
%hook SBDockIconListView
- (void)didMoveToWindow {
    %orig;
    [(UIView *)self setHidden:ShouldHide()];
}
- (void)layoutSubviews {
    %orig;
    [(UIView *)self setHidden:ShouldHide()];
}
%end

%ctor {
    @autoreleasepool {
        LoadPrefs();
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, Changed,
          CFSTR("com.aincrad.ui/preferences.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}
