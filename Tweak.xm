#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// Exploratory private SpringBoard hooks: not validated on iOS 16.7.16.
// Disabled by default for safer installation.
static BOOL gEnabled = NO;
static BOOL gHideDock = YES;

static void LoadPrefs(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.aincrad.ui.plist"];
    gEnabled = [prefs[@"Enabled"] boolValue];
    gHideDock = prefs[@"HideDock"] ? [prefs[@"HideDock"] boolValue] : YES;
}

%hook SBIconController
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return gEnabled ? UIInterfaceOrientationMaskAllButUpsideDown : %orig;
}
- (BOOL)shouldAutorotate {
    return gEnabled ? YES : %orig;
}
%end

%hook SBRootFolderController
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return gEnabled ? UIInterfaceOrientationMaskAllButUpsideDown : %orig;
}
- (BOOL)shouldAutorotate {
    return gEnabled ? YES : %orig;
}
%end

%hook SBDockIconListView
- (void)didMoveToWindow {
    %orig;
    if (gEnabled && gHideDock) self.hidden = YES;
}
- (void)layoutSubviews {
    %orig;
    if (gEnabled && gHideDock) self.hidden = YES;
}
%end

%ctor {
    @autoreleasepool {
        LoadPrefs();
        NSLog(@"[AincradUI] loaded enabled=%d hideDock=%d", gEnabled, gHideDock);
    }
}
