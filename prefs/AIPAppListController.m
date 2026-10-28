#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/message.h>

static NSString * const kAIPPrefs = @"/var/mobile/Library/Preferences/com.aincrad.ui.plist";
@interface AIPAppListController : PSListController
@end
@implementation AIPAppListController
- (NSArray *)specifiers {
    if (_specifiers) return _specifiers;
    NSMutableArray *items = [NSMutableArray new];
    PSSpecifier *heading = [PSSpecifier preferenceSpecifierNamed:@"仅选择需要强制横屏的应用" target:self set:NULL get:NULL detail:Nil cell:PSGroupCell edit:Nil];
    [heading setProperty:@"默认全部关闭。应用可能无法正确布局；关闭对应开关即可恢复。" forKey:@"footerText"];
    [items addObject:heading];
    Class wsClass = NSClassFromString(@"LSApplicationWorkspace");
    id workspace = wsClass && [wsClass respondsToSelector:NSSelectorFromString(@"defaultWorkspace")] ?
        ((id (*)(id, SEL))objc_msgSend)(wsClass, NSSelectorFromString(@"defaultWorkspace")) : nil;
    NSArray *apps = workspace && [workspace respondsToSelector:NSSelectorFromString(@"allInstalledApplications")] ?
        ((id (*)(id, SEL))objc_msgSend)(workspace, NSSelectorFromString(@"allInstalledApplications")) : @[];
    NSMutableDictionary *names = [NSMutableDictionary new];
    for (id app in apps) {
        SEL idSel = NSSelectorFromString(@"applicationIdentifier");
        SEL nameSel = NSSelectorFromString(@"localizedName");
        if (![app respondsToSelector:idSel] || ![app respondsToSelector:nameSel]) continue;
        NSString *bundle = ((id (*)(id, SEL))objc_msgSend)(app, idSel);
        NSString *name = ((id (*)(id, SEL))objc_msgSend)(app, nameSel);
        if (![bundle isKindOfClass:NSString.class] || ![name isKindOfClass:NSString.class]) continue;
        if ([bundle hasPrefix:@"com.apple."] || [bundle hasPrefix:@"com.aincrad."]) continue;
        names[bundle] = name;
    }
    NSArray *bundleIDs = [[names allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        NSComparisonResult result = [names[a] localizedStandardCompare:names[b]];
        return result == NSOrderedSame ? [a compare:b] : result;
    }];
    for (NSString *bundle in bundleIDs) {
        PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:names[bundle] target:self set:@selector(setAppValue:specifier:) get:@selector(readAppValue:) detail:Nil cell:PSSwitchCell edit:Nil];
        [spec setProperty:bundle forKey:@"appBundleID"];
        [spec setProperty:@NO forKey:@"default"];
        [items addObject:spec];
    }
    if (!bundleIDs.count) {
        PSSpecifier *empty = [PSSpecifier preferenceSpecifierNamed:@"无法读取已安装应用列表" target:self set:NULL get:NULL detail:Nil cell:PSStaticTextCell edit:Nil];
        [items addObject:empty];
    }
    _specifiers = [items copy];
    return _specifiers;
}
- (id)readAppValue:(PSSpecifier *)specifier {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:kAIPPrefs];
    NSArray *chosen = dict[@"AppLandscapeIDs"];
    return @([chosen isKindOfClass:NSArray.class] && [chosen containsObject:[specifier propertyForKey:@"appBundleID"]]);
}
- (void)setAppValue:(id)value specifier:(PSSpecifier *)specifier {
    NSMutableDictionary *dict = [[NSDictionary dictionaryWithContentsOfFile:kAIPPrefs] mutableCopy] ?: [NSMutableDictionary new];
    NSMutableSet *chosen = [NSMutableSet setWithArray:[dict[@"AppLandscapeIDs"] isKindOfClass:NSArray.class] ? dict[@"AppLandscapeIDs"] : @[]];
    NSString *bundle = [specifier propertyForKey:@"appBundleID"];
    if (![bundle isKindOfClass:NSString.class]) return;
    if ([value boolValue]) [chosen addObject:bundle]; else [chosen removeObject:bundle];
    dict[@"AppLandscapeIDs"] = [[chosen allObjects] sortedArrayUsingSelector:@selector(compare:)];
    [dict writeToFile:kAIPPrefs atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.aincrad.ui/preferences.changed"), NULL, NULL, YES);
}
@end
