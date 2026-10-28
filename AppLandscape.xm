#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <CoreFoundation/CoreFoundation.h>
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

static void AIPRequestLandscape(void) {
    if (!AIPSelected()) return;
    if (@available(iOS 16.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            if (scene.activationState != UISceneActivationStateForegroundActive) continue;
            UIWindowSceneGeometryPreferencesIOS *prefs =
                [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:UIInterfaceOrientationMaskLandscape];
            [(UIWindowScene *)scene requestGeometryUpdateWithPreferences:prefs errorHandler:^(NSError *error) {
                NSLog(@"[AincradUI] app landscape request failed: %@", error);
            }];
        }
    }
}
static void AIPAppActivated(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef info) {
    if (AIPSelected()) dispatch_async(dispatch_get_main_queue(), ^{ AIPRequestLandscape(); });
}
%hook NSBundle
- (id)objectForInfoDictionaryKey:(NSString *)key {
    if (self == [NSBundle mainBundle] && AIPSelected() &&
        ([key isEqualToString:@"UISupportedInterfaceOrientations"] ||
         [key isEqualToString:@"UISupportedInterfaceOrientations~iphone"])) {
        return @[@"UIInterfaceOrientationLandscapeLeft", @"UIInterfaceOrientationLandscapeRight"];
    }
    return %orig;
}
%end
%ctor {
    @autoreleasepool {
        if (AIPSelected()) {
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) { AIPRequestLandscape(); }];
        }
    }
}
