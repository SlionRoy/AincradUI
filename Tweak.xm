#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

static BOOL gEnabled = NO;
static BOOL gHideDock = YES;
static BOOL gLandscape = NO;
static BOOL gHUD = YES;
static NSString * const kPrefsPath = @"/var/mobile/Library/Preferences/com.aincrad.ui.plist";
static void LoadPrefs(void) {
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];
    gEnabled = [p[@"Enabled"] boolValue];
    gHideDock = p[@"HideDock"] ? [p[@"HideDock"] boolValue] : YES;
    gLandscape = [p[@"Landscape"] boolValue];
    gHUD = p[@"HUD"] ? [p[@"HUD"] boolValue] : YES;
}
static void Changed(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) { LoadPrefs(); }
static BOOL ShouldHide(void) { return gEnabled && gHideDock; }
static BOOL ShouldRotate(void) { return gEnabled && gLandscape; }

// Passive overlay: attaches to the home-screen controller only. It does not intercept touches.
static const NSInteger kHUDTag = 0xA1C7;
static void UpdateHUD(UIView *host) {
    if (!host) return;
    UIView *old = [host viewWithTag:kHUDTag];
    if (!gEnabled || !gHUD) { [old removeFromSuperview]; return; }
    if (old) return;
    UIView *panel = [[UIView alloc] initWithFrame:CGRectZero];
    panel.tag = kHUDTag;
    panel.userInteractionEnabled = NO;
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.backgroundColor = [[UIColor colorWithRed:0.08 green:0.18 blue:0.32 alpha:1] colorWithAlphaComponent:0.64];
    panel.layer.cornerRadius = 12;
    panel.layer.borderWidth = 1;
    panel.layer.borderColor = [UIColor colorWithRed:0.63 green:0.83 blue:1 alpha:0.75].CGColor;
    UILabel *text = [[UILabel alloc] initWithFrame:CGRectZero];
    text.text = @"✧ ASUNA   /   AINCRAD SYSTEM";
    text.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    text.textColor = [UIColor colorWithRed:0.90 green:0.96 blue:1 alpha:1];
    text.textAlignment = NSTextAlignmentCenter;
    text.translatesAutoresizingMaskIntoConstraints = NO;
    [panel addSubview:text];
    [host addSubview:panel];
    [NSLayoutConstraint activateConstraints:@[
        [panel.centerXAnchor constraintEqualToAnchor:host.centerXAnchor],
        [panel.topAnchor constraintEqualToAnchor:host.safeAreaLayoutGuide.topAnchor constant:8],
        [panel.widthAnchor constraintLessThanOrEqualToAnchor:host.widthAnchor multiplier:0.86],
        [panel.heightAnchor constraintEqualToConstant:34],
        [text.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:18],
        [text.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-18],
        [text.centerYAnchor constraintEqualToAnchor:panel.centerYAnchor]
    ]];
}

%hook SBIconController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    UpdateHUD([(UIViewController *)self view]);
}
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
