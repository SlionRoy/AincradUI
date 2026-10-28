#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <math.h>

static BOOL gEnabled = NO;
static BOOL gHideDock = YES;
static BOOL gLandscape = NO;
static BOOL gLandscapeLock = NO;
static BOOL gHUD = YES;
static BOOL gNCWallpaper = NO;
static BOOL gHomeWallpaper = NO;
static BOOL gSystemLandscape = NO;
static BOOL gControlCenterLandscape = NO;
static BOOL gSAOMenu = NO;
static CGFloat gScaleValue = 1.0;
static CGFloat AincradScale(void) { return gEnabled ? gScaleValue : 1.0; }
static NSString * const kPrefsPath = @"/var/mobile/Library/Preferences/com.aincrad.ui.plist";
static void LoadPrefs(void) {
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];
    gEnabled = [p[@"Enabled"] boolValue];
    gHideDock = p[@"HideDock"] ? [p[@"HideDock"] boolValue] : YES;
    gLandscape = [p[@"Landscape"] boolValue];
    gLandscapeLock = [p[@"LandscapeLock"] boolValue];
    gHUD = p[@"HUD"] ? [p[@"HUD"] boolValue] : YES;
    gNCWallpaper = [p[@"NCWallpaper"] boolValue];
    gHomeWallpaper = [p[@"HomeWallpaper"] boolValue];
    gSystemLandscape = [p[@"SystemLandscape"] boolValue];
    gControlCenterLandscape = [p[@"ControlCenterLandscape"] boolValue];
    gSAOMenu = [p[@"SAOMenu"] boolValue];
    // Preserve old v1.7 choices when upgrading, unless a slider value was saved.
    id value = p[@"ScaleValue"];
    CGFloat ratio = value ? [value doubleValue] : ([p[@"ScaleMode"] integerValue] == 1 ? 0.90 : ([p[@"ScaleMode"] integerValue] == 2 ? 0.84 : 1.0));
    gScaleValue = isfinite(ratio) ? MIN(1.0, MAX(0.65, ratio)) : 1.0;
}
static void Changed(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) { LoadPrefs(); }
static BOOL ShouldSystemLandscape(void) { return gEnabled && gSystemLandscape; }
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
    panel.layer.cornerRadius = 12 * AincradScale();
    panel.layer.borderWidth = 1;
    panel.layer.borderColor = [UIColor colorWithRed:0.63 green:0.83 blue:1 alpha:0.75].CGColor;
    UILabel *text = [[UILabel alloc] initWithFrame:CGRectZero];
    text.text = @"✧ ASUNA   /   AINCRAD SYSTEM";
    text.font = [UIFont systemFontOfSize:12 * AincradScale() weight:UIFontWeightSemibold];
    text.textColor = [UIColor colorWithRed:0.90 green:0.96 blue:1 alpha:1];
    text.textAlignment = NSTextAlignmentCenter;
    text.translatesAutoresizingMaskIntoConstraints = NO;
    [panel addSubview:text];
    [host addSubview:panel];
    [NSLayoutConstraint activateConstraints:@[
        [panel.trailingAnchor constraintEqualToAnchor:host.safeAreaLayoutGuide.trailingAnchor constant:-14],
        [panel.topAnchor constraintEqualToAnchor:host.safeAreaLayoutGuide.topAnchor constant:14],
        [panel.widthAnchor constraintLessThanOrEqualToAnchor:host.widthAnchor multiplier:0.86],
        [panel.heightAnchor constraintEqualToConstant:34 * AincradScale()],
        [text.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:18 * AincradScale()],
        [text.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-18 * AincradScale()],
        [text.centerYAnchor constraintEqualToAnchor:panel.centerYAnchor]
    ]];
}


static const NSInteger kSAOEntryTag = 0xA1D0;
static const NSInteger kSAOPanelTag = 0xA1D1;
static const NSInteger kSAOStatusTag = 0xA1D2;
@interface AincradMenuActions : NSObject
- (void)toggle:(UIButton *)sender;
- (void)close:(UIButton *)sender;
- (void)status:(UIButton *)sender;
- (void)submenu:(UIButton *)sender;
@end
@implementation AincradMenuActions
- (void)toggle:(UIButton *)sender {
    UIView *host = sender.superview;
    if (!host) return;
    UIView *old = [host viewWithTag:kSAOPanelTag];
    if (old) { [UIView animateWithDuration:0.18 animations:^{ old.alpha = 0; old.transform = CGAffineTransformMakeScale(0.94, 0.94); } completion:^(BOOL finished) { [old removeFromSuperview]; }]; return; }
    UIView *panel = [[UIView alloc] initWithFrame:CGRectZero];
    panel.tag = kSAOPanelTag;
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.backgroundColor = [UIColor colorWithRed:0.055 green:0.105 blue:0.19 alpha:0.72];
    panel.layer.cornerRadius = 17 * AincradScale();
    panel.layer.shadowColor = [UIColor colorWithRed:0.25 green:0.72 blue:1 alpha:1].CGColor;
    panel.layer.shadowOpacity = 0.25;
    panel.layer.shadowRadius = 18;
    panel.layer.shadowOffset = CGSizeMake(0, 6);
    panel.layer.borderWidth = 1;
    panel.layer.borderColor = [UIColor colorWithRed:0.68 green:0.86 blue:1 alpha:0.9].CGColor;
    UILabel *heading = [UILabel new];
    heading.text = @"✧ AINCRAD  /  MENU";
    heading.textColor = [UIColor whiteColor];
    heading.font = [UIFont systemFontOfSize:13 * AincradScale() weight:UIFontWeightSemibold];
    heading.translatesAutoresizingMaskIntoConstraints = NO;
    [panel addSubview:heading];
    UILabel *status = [UILabel new];
    status.tag = kSAOStatusTag;
    status.text = @"SYSTEM ONLINE · 01";
    status.textColor = [UIColor colorWithRed:0.78 green:0.9 blue:1 alpha:1];
    status.font = [UIFont systemFontOfSize:12 * AincradScale()];
    status.translatesAutoresizingMaskIntoConstraints = NO;
    [panel addSubview:status];
    UIButton *sub = [UIButton buttonWithType:UIButtonTypeSystem];
    [sub setTitle:@"◇ 系统功能  ›" forState:UIControlStateNormal];
    [sub setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    sub.backgroundColor = [UIColor colorWithRed:0.12 green:0.26 blue:0.43 alpha:0.78];
    sub.layer.cornerRadius = 8;
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    [sub addTarget:self action:@selector(submenu:) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:sub];
    UIButton *info = [UIButton buttonWithType:UIButtonTypeSystem];
    [info setTitle:@"查看系统状态" forState:UIControlStateNormal];
    [info setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    info.backgroundColor = [UIColor colorWithRed:0.13 green:0.28 blue:0.47 alpha:1];
    info.layer.cornerRadius = 8;
    info.translatesAutoresizingMaskIntoConstraints = NO;
    [info addTarget:self action:@selector(status:) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:info];
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"返回" forState:UIControlStateNormal];
    [close setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    [close addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:close];
    [host addSubview:panel];
    [NSLayoutConstraint activateConstraints:@[
        [panel.trailingAnchor constraintEqualToAnchor:host.safeAreaLayoutGuide.trailingAnchor constant:-14],
        [panel.centerYAnchor constraintEqualToAnchor:host.centerYAnchor],
        [panel.widthAnchor constraintEqualToConstant:228 * AincradScale()],
        [panel.heightAnchor constraintEqualToConstant:198 * AincradScale()],
        [heading.topAnchor constraintEqualToAnchor:panel.topAnchor constant:15],
        [heading.centerXAnchor constraintEqualToAnchor:panel.centerXAnchor],
        [status.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:12],
        [status.centerXAnchor constraintEqualToAnchor:panel.centerXAnchor],
        [sub.topAnchor constraintEqualToAnchor:status.bottomAnchor constant:12],
        [sub.centerXAnchor constraintEqualToAnchor:panel.centerXAnchor],
        [sub.widthAnchor constraintEqualToConstant:194],
        [sub.heightAnchor constraintEqualToConstant:32],
        [info.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:7],
        [info.centerXAnchor constraintEqualToAnchor:panel.centerXAnchor],
        [info.widthAnchor constraintEqualToConstant:194],
        [info.heightAnchor constraintEqualToConstant:32],
        [close.topAnchor constraintEqualToAnchor:info.bottomAnchor constant:6],
        [close.centerXAnchor constraintEqualToAnchor:panel.centerXAnchor]
    ]];
    panel.alpha = 0;
    panel.transform = CGAffineTransformMakeTranslation(24, 0);
    [UIView animateWithDuration:0.26 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        panel.alpha = 1;
        panel.transform = CGAffineTransformIdentity;
    } completion:nil];
}
- (void)close:(UIButton *)sender {
    UIView *panel = sender.superview;
    if (panel.tag == kSAOPanelTag) {
        [UIView animateWithDuration:0.18 animations:^{ panel.alpha = 0; panel.transform = CGAffineTransformMakeTranslation(18, 0); } completion:^(BOOL finished) { [panel removeFromSuperview]; }];
    }
}
- (void)status:(UIButton *)sender {
    UILabel *status = (UILabel *)[sender.superview viewWithTag:kSAOStatusTag];
    if ([status isKindOfClass:[UILabel class]]) {
        status.text = [NSString stringWithFormat:@"桌面横屏：%@  ·  HUD：%@", gLandscape ? @"开" : @"关", gHUD ? @"开" : @"关"];
    }
}
- (void)submenu:(UIButton *)sender {
    UIView *panel = sender.superview;
    UILabel *status = (UILabel *)[panel viewWithTag:kSAOStatusTag];
    if (![status isKindOfClass:UILabel.class]) return;
    status.text = @"SYSTEM / 界面设置";
    [UIView transitionWithView:status duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        status.text = @"SYSTEM / 界面设置";
    } completion:nil];
}
@end
static AincradMenuActions *gMenuActions;
static void UpdateSAOMenu(UIView *host) {
    if (!host) return;
    UIView *entry = [host viewWithTag:kSAOEntryTag];
    UIView *panel = [host viewWithTag:kSAOPanelTag];
    if (!gEnabled || !gSAOMenu) {
        [entry removeFromSuperview];
        [panel removeFromSuperview];
        return;
    }
    if (entry) return;
    if (!gMenuActions) gMenuActions = [AincradMenuActions new];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.tag = kSAOEntryTag;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:@"✧ MENU" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:12 * AincradScale() weight:UIFontWeightBold];
    button.backgroundColor = [UIColor colorWithRed:0.08 green:0.2 blue:0.36 alpha:0.86];
    button.layer.cornerRadius = 18;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor colorWithRed:0.65 green:0.86 blue:1 alpha:0.85].CGColor;
    [button addTarget:gMenuActions action:@selector(toggle:) forControlEvents:UIControlEventTouchUpInside];
    [host addSubview:button];
    [NSLayoutConstraint activateConstraints:@[
        [button.trailingAnchor constraintEqualToAnchor:host.safeAreaLayoutGuide.trailingAnchor constant:-12],
        [button.bottomAnchor constraintEqualToAnchor:host.safeAreaLayoutGuide.bottomAnchor constant:-14],
        [button.widthAnchor constraintEqualToConstant:78 * AincradScale()],
        [button.heightAnchor constraintEqualToConstant:36 * AincradScale()]
    ]];
}

static void AincradUpdateHomeWallpaper(UIView *host);

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
- (void)viewDidLayoutSubviews {
    %orig;
    AincradUpdateHomeWallpaper([(UIViewController *)self view]);
    UpdateSAOMenu([(UIViewController *)self view]);
}
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    AincradUpdateHomeWallpaper([(UIViewController *)self view]);
    UpdateHUD([(UIViewController *)self view]);
    UpdateSAOMenu([(UIViewController *)self view]);
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
static const NSInteger kHomeWallpaperTag = 0xA1C9;
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

// Home background is opt-in and only mounted within the icon-controller view.
// It is noninteractive and inserted behind the existing icon views.
static void AincradUpdateHomeWallpaper(UIView *host) {
    if (!host) return;
    UIView *existing = [host viewWithTag:kHomeWallpaperTag];
    BOOL horizontal = CGRectGetWidth(host.bounds) > CGRectGetHeight(host.bounds);
    if (!gEnabled || !gHomeWallpaper || !horizontal) {
        [existing removeFromSuperview];
        return;
    }
    UIImage *image = [UIImage imageWithContentsOfFile:kCustomWallpaperPath];
    if (!image) {
        [existing removeFromSuperview];
        return;
    }
    UIImageView *background = [existing isKindOfClass:[UIImageView class]] ? (UIImageView *)existing : nil;
    if (!background) {
        [existing removeFromSuperview];
        background = [[UIImageView alloc] initWithFrame:host.bounds];
        background.tag = kHomeWallpaperTag;
        background.userInteractionEnabled = NO;
        background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        background.contentMode = UIViewContentModeScaleAspectFill;
        background.clipsToBounds = YES;
        [host insertSubview:background atIndex:0];
    }
    background.frame = host.bounds;
    if (background.image != image) background.image = image;
    [host sendSubviewToBack:background];
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
    if (imageView.image != wallpaper) imageView.image = wallpaper;
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
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return ShouldSystemLandscape() ? UIInterfaceOrientationMaskLandscape : %orig;
}
- (BOOL)shouldAutorotate {
    return ShouldSystemLandscape() ? YES : %orig;
}
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    AincradUpdateNCWallpaper([(UIViewController *)self view]);
}
- (void)viewDidLayoutSubviews {
    %orig;
    AincradUpdateNCWallpaper([(UIViewController *)self view]);
}
%end

// Control Center policy: isolated, opt-in, and only when the screen is landscape.
// The module grid is not resized or replaced; failure is safe to disable.
%hook CCUIModularControlCenterOverlayViewController
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return (gEnabled && gControlCenterLandscape) ? UIInterfaceOrientationMaskLandscape : %orig;
}
- (BOOL)shouldAutorotate {
    return (gEnabled && gControlCenterLandscape) ? YES : %orig;
}
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (gEnabled && gControlCenterLandscape) {
        UIView *v = [(UIViewController *)self view];
        AincradDiag([NSString stringWithFormat:@"control-center host=%@ size=%@", NSStringFromClass([v class]), NSStringFromCGRect(v.bounds)]);
    }
}
%end


// Compact mode scales icon views around their centers without modifying SpringBoard's grid,
// hit-test routing or folder data. Kept separate from the existing rotation hooks.
// The outer view frame remains system-managed to avoid layout recursion.
%hook SBIconView
- (void)layoutSubviews {
    %orig;
    CGFloat factor = AincradScale();
    CGAffineTransform wanted = CGAffineTransformMakeScale(factor, factor);
    if (!CGAffineTransformEqualToTransform(((UIView *)self).transform, wanted)) {
        ((UIView *)self).transform = wanted;
    }
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
