#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/message.h>
#import <objc/runtime.h>

static BOOL gEnabled = NO;
static BOOL gHideDock = YES;
static BOOL gLandscape = NO;
static BOOL gLandscapeLock = NO;
static BOOL gHUD = YES;
static BOOL gNCWallpaper = NO;
static NSString * const kPrefsPath = @"/var/mobile/Library/Preferences/com.aincrad.ui.plist";
static void LoadPrefs(void) {
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];
    gEnabled = [p[@"Enabled"] boolValue];
    gHideDock = p[@"HideDock"] ? [p[@"HideDock"] boolValue] : YES;
    gLandscape = [p[@"Landscape"] boolValue];
    gLandscapeLock = [p[@"LandscapeLock"] boolValue];
    gHUD = p[@"HUD"] ? [p[@"HUD"] boolValue] : YES;
    gNCWallpaper = [p[@"NCWallpaper"] boolValue];
}
static void Changed(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) { LoadPrefs(); }
static BOOL ShouldHide(void) { return gEnabled && gHideDock; }
static BOOL ShouldRotate(void) { return gEnabled && gLandscape; }
static UIInterfaceOrientationMask HomeOrientationMask(void) {
    return (ShouldRotate() && gLandscapeLock) ? UIInterfaceOrientationMaskLandscape : UIInterfaceOrientationMaskAllButUpsideDown;
}

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

// Native SpringBoard home-screen rotation policy. Based on documented open-source
// AutoRotate hooks (MIT), without app, lock-screen or Control Center overrides.
// Private selectors may differ on iOS 16.7.16: experimental, off by default.
%hook SpringBoard
- (BOOL)homeScreenSupportsRotation {
    return ShouldRotate() ? YES : %orig;
}
- (long long)homeScreenRotationStyle {
    return ShouldRotate() ? 1 : %orig;
}
%end

%hook SBHomeScreenViewController
- (BOOL)shouldAutorotate {
    return ShouldRotate() ? YES : %orig;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return ShouldRotate() ? HomeOrientationMask() : %orig;
}
%end

%hook SBIconController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    UpdateHUD([(UIViewController *)self view]);
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return ShouldRotate() ? HomeOrientationMask() : %orig;
}
- (BOOL)shouldAutorotate {
    return ShouldRotate() ? YES : %orig;
}
%end

%hook SBRootFolderController
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return ShouldRotate() ? HomeOrientationMask() : %orig;
}
- (BOOL)shouldAutorotate {
    return ShouldRotate() ? YES : %orig;
}
%end


/* Experimental, isolated landscape Notification Center wallpaper.
 * Uses SpringBoard wallpaper controller at runtime. No system files altered.
 * Falls back to native background if no UIImage can be obtained.
 */
static const NSInteger kNCWallpaperTag = 0xA1C8;
static NSString * const kCustomWallpaperPath = @"/var/mobile/Library/AincradUI/NCWallpaper.jpg";
static void AincradDiag(NSString *line) {
    NSString *path = @"/var/mobile/Library/AincradUI/diagnostic.txt";
    NSString *dir = [path stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *entry = [NSString stringWithFormat:@"%@ %@\\n", [NSDate date], line];
    NSFileHandle *h = [NSFileHandle fileHandleForWritingAtPath:path];
    if (h) {
        [h seekToEndOfFile];
        [h writeData:[entry dataUsingEncoding:NSUTF8StringEncoding]];
        [h closeFile];
    } else {
        [entry writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}
static UIImage *AincradCustomWallpaper(void) {
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:kCustomWallpaperPath error:nil];
    UIImage *im = [UIImage imageWithContentsOfFile:kCustomWallpaperPath];
    static BOOL recorded = NO;
    if (!recorded) {
        recorded = YES;
        AincradDiag([NSString stringWithFormat:@"custom path=%@ bytes=%@ decoded=%@",
            kCustomWallpaperPath, attrs[NSFileSize] ?: @"missing", im ? @"yes" : @"no"]);
    }
    return im;
}
static void AincradUpdateNCWallpaper(UIView *host) {
    if (!host) return;
    UIView *existing = [host viewWithTag:kNCWallpaperTag];
    BOOL horizontal = CGRectGetWidth(host.bounds) > CGRectGetHeight(host.bounds);
    if (!gEnabled || !gNCWallpaper || !horizontal) {
        [existing removeFromSuperview];
        return;
    }
    static NSMutableSet *loggedClasses;
    if (!loggedClasses) loggedClasses = [NSMutableSet new];
    NSString *key = NSStringFromClass([host class]);
    if (![loggedClasses containsObject:key]) {
        [loggedClasses addObject:key];
        AincradDiag([NSString stringWithFormat:@"hook=%@ bounds=%@ childCount=%lu",
            key, NSStringFromCGRect(host.bounds), (unsigned long)host.subviews.count]);
    }
    UIImage *wallpaper = AincradCustomWallpaper();
    if (!wallpaper) { [existing removeFromSuperview]; return; }
    UIImageView *imageView = [existing isKindOfClass:[UIImageView class]] ? (UIImageView *)existing : nil;
    if (!imageView) {
        [existing removeFromSuperview];
        imageView = [[UIImageView alloc] initWithFrame:host.bounds];
        imageView.tag = kNCWallpaperTag;
        imageView.userInteractionEnabled = NO;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [host insertSubview:imageView atIndex:0];
    }
    imageView.frame = host.bounds;
    imageView.image = wallpaper;
}
%hook SBNotificationCenterViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    AincradUpdateNCWallpaper([(UIViewController *)self view]);
}
- (void)viewDidLayoutSubviews {
    %orig;
    AincradUpdateNCWallpaper([(UIViewController *)self view]);
}
%end

// CoverSheet is the iOS 13+ combined lock screen / notification center surface.
// The feature remains disabled until opted in, and only acts when landscape.
%hook CSCoverSheetViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    AincradUpdateNCWallpaper([(UIViewController *)self view]);
}
- (void)viewDidLayoutSubviews {
    %orig;
    AincradUpdateNCWallpaper([(UIViewController *)self view]);
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
