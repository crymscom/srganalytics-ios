//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

#import "SRGAnalyticsNetMetrixTracker.h"

#import "NSString+SRGAnalytics.h"
#import "NSDictionary+SRGAnalytics.h"
#import "SRGAnalyticsLogger.h"
#import "UIViewController+SRGAnalytics.h"

#import <ComScore/CSCore.h>
#import <ComScore/CSComScore.h>
#import <ComScore/CSTaskExecutor.h>
#import <UIKit/UIKit.h>

NSString *const SRGAnalyticsNetmetrixRequestNotification = @"SRGAnalyticsNetmetrixRequestDidFinish";
NSString *const SRGAnalyticsNetmetrixRequestSuccessUserInfoKey = @"SRGAnalyticsNetmetrixSuccess";
NSString *const SRGAnalyticsNetmetrixRequestErrorUserInfoKey = @"SRGAnalyticsNetmetrixError";
NSString *const SRGAnalyticsNetmetrixRequestResponseUserInfoKey = @"SRGAnalyticsNetmetrixResponse";

@interface SRGAnalyticsTracker () {
@private
    BOOL _debugMode;
}
@property (nonatomic, strong) SRGAnalyticsNetMetrixTracker *netmetrixTracker;
@property (nonatomic, weak) id<SRGAnalyticsViewTracking> lastPageViewDataSource;
@property (nonatomic, assign) SSRBusinessUnit businessUnit;
@property (nonatomic, strong) NSString *comScoreVirtualSite;
@property (nonatomic, strong) NSString *netMetrixIdentifier;
@end

@implementation SRGAnalyticsTracker

+ (instancetype)sharedTracker
{
    static SRGAnalyticsTracker *sharedInstance = nil;
    static dispatch_once_t SRGAnalyticsTracker_onceToken;
    dispatch_once(&SRGAnalyticsTracker_onceToken, ^{
        sharedInstance = [[[self class] alloc] init_custom_SRGAnalyticsTracker];
    });
    return sharedInstance;
}

- (id)init_custom_SRGAnalyticsTracker
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self trackPageViewForObject:self.lastPageViewDataSource];
}

#pragma mark - Accessors

- (NSArray *)businessUnits
{
    return @[ @"SRF", @"RTS", @"RSI", @"RTR", @"SWI" ];
}

- (NSString *)businessUnitIdentifier:(SSRBusinessUnit)businessUnit
{
    return [self.businessUnits[businessUnit] lowercaseString];
}

- (SSRBusinessUnit)businessUnitForIdentifier:(NSString *)buIdentifier
{
    NSUInteger index = [self.businessUnits indexOfObject:buIdentifier.uppercaseString];
    NSAssert(index != NSNotFound, @"Business unit not found with identifier '%@'", buIdentifier);
    return (SSRBusinessUnit)index;
}

#pragma mark - PageView tracking

- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit
             withComScoreVirtualSite:(NSString *)comScoreVirtualSite
                 netMetrixIdentifier:(NSString *)netMetrixIdentifier
                           debugMode:(BOOL)debugMode
{
    _businessUnit = businessUnit;
    _debugMode = debugMode;
    
    self.comScoreVirtualSite = comScoreVirtualSite;
    self.netMetrixIdentifier = netMetrixIdentifier;
    
    [self startComscoreTracker];
    [self startNetmetrixTracker];
}

- (void)startComscoreTracker
{
    [CSComScore setAppContext];
    [CSComScore setCustomerC2:@"6036016"];
    [CSComScore setPublisherSecret:@"b19346c7cb5e521845fb032be24b0154"];
    [CSComScore enableAutoUpdate:60 foregroundOnly:NO];     //60 is the Comscore default interval value
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ? : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (appName) {
        [CSComScore setAutoStartLabels:@{ @"name": appName }];
    }
    [CSComScore setLabels:[self comscoreGlobalLabels]];
    
    [self startLoggingInternalComScoreTasks];
}

- (NSDictionary *)comscoreGlobalLabels
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSString *appName = [[mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"] stringByAppendingString:@" iOS"];
    NSString *appLanguage = [[mainBundle preferredLocalizations] firstObject] ? : @"fr";
    NSString *appVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    NSMutableDictionary *globalLabels = [@{ @"ns_ap_an": appName,
                                            @"ns_ap_lang": [NSLocale canonicalLanguageIdentifierFromString:appLanguage],
                                            @"ns_ap_ver": appVersion,
                                            @"srg_unit": [self businessUnitIdentifier:self.businessUnit].uppercaseString,
                                            @"srg_ap_push": @"0",
                                            @"ns_site": @"mainsite", // MGubler 17-Nov-2015: This 'mainsite' is a constant value. If wrong, everything is screwed.
                                            @"ns_vsite": self.comScoreVirtualSite } mutableCopy]; // MGubler 17-Nov-2015: 'vsite' is associated with the app. It is created by comScore itself.
    // Even if it is 'easy' to create a new one (for new/easier repoSRG, or fixing wrong values),
    // this must never change for the given app.
    if (_debugMode) {
        static NSString *debugTimestamp;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'@'HH:mm:ss"];
            debugTimestamp = [dateFormatter stringFromDate:[NSDate date]];
        });
        globalLabels[@"srg_test"] = debugTimestamp;
    }
    return [globalLabels copy];
}

- (void)startNetmetrixTracker
{
    self.netmetrixTracker = [[SRGAnalyticsNetMetrixTracker alloc] initWithIdentifier:self.netMetrixIdentifier businessUnit:self.businessUnit];
}

#pragma mark - PageView tracking

- (void)trackPageViewForObject:(id<SRGAnalyticsViewTracking>)dataSource
{
    _lastPageViewDataSource = dataSource;
    
    if (! dataSource) {
        return;
    }
    
    NSString *title = [dataSource srg_pageViewTitle];
    NSArray *levels = nil;
    
    if ([dataSource respondsToSelector:@selector(srg_pageViewLevels)]) {
        levels = [dataSource srg_pageViewLevels];
    }
    
    NSDictionary *customLabels = nil;
    if ([dataSource respondsToSelector:@selector(srg_pageViewCustomLabels)]) {
        customLabels = [dataSource srg_pageViewCustomLabels];
    }
    
    BOOL fromPushNotification = NO;
    if ([dataSource respondsToSelector:@selector(srg_isOpenedFromPushNotification)]) {
        fromPushNotification = [dataSource srg_isOpenedFromPushNotification];
    }
    
    [self trackPageViewTitle:title levels:levels customLabels:customLabels fromPushNotification:fromPushNotification];
}

- (void)trackPageViewTitle:(NSString *)title levels:(NSArray *)levels
{
    [self trackPageViewTitle:title levels:levels customLabels:nil fromPushNotification:NO];
}

- (void)trackPageViewTitle:(NSString *)title levels:(NSArray *)levels customLabels:(NSDictionary *)customLabels fromPushNotification:(BOOL)fromPush
{
    NSMutableDictionary *labels = [NSMutableDictionary dictionary];
    
    title = title.length > 0 ? title.srg_comScoreTitleFormattedString : @"untitled";
    [labels safeSetValue:title forKey:@"srg_title"];
    [labels safeSetValue:@(fromPush) forKey:@"srg_ap_push"];
    
    NSString *category = @"app";
    
    if (! levels) {
        [labels safeSetValue:category forKey:@"srg_n1"];
    }
    else if (levels.count > 0) {
        __block NSMutableString *levelsConcatenation = [NSMutableString new];
        [levels enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL *stop) {
            NSString *levelKey = [NSString stringWithFormat:@"srg_n%tu", idx + 1];
            NSString *levelValue = [value description].srg_comScoreFormattedString;
            
            if (idx < 10) {
                [labels safeSetValue:levelValue forKey:levelKey];
            }
            
            if (levelsConcatenation.length > 0) {
                [levelsConcatenation appendString:@"."];
            }
            [levelsConcatenation appendString:levelValue];
        }];
        
        category = [levelsConcatenation copy];
    }
    
    [labels safeSetValue:category forKey:@"category"];
    [labels safeSetValue:[NSString stringWithFormat:@"%@.%@", category, title.srg_comScoreFormattedString] forKey:@"name"];
    
    [customLabels enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [labels safeSetValue:[obj description] forKey:[key description]];
    }];
    
    [CSComScore viewWithLabels:labels];
    
    [self.netmetrixTracker trackView];
}

- (void)trackHiddenEventWithTitle:(NSString *)title
{
    [self trackHiddenEventWithTitle:title customLabels:nil];
}

- (void)trackHiddenEventWithTitle:(NSString *)title customLabels:(NSDictionary *)customLabels
{
    NSMutableDictionary *labels = [NSMutableDictionary dictionary];
    
    title = title.length > 0 ? title.srg_comScoreTitleFormattedString : @"untitled";
    [labels safeSetValue:title forKey:@"srg_title"];
    
    [customLabels enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [labels safeSetValue:[obj description] forKey:[key description]];
    }];
    
    [CSComScore hiddenWithLabels:labels];
}

#pragma mark Logging

- (void)startLoggingInternalComScoreTasks
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(comScoreRequestDidFinish:)
                                                 name:SRGAnalyticsComScoreRequestNotification
                                               object:nil];
    
    // +[CSComScore setPixelURL:] is dispatched on an internal comScore queue, so calling +[CSComScore pixelURL]
    // right after doesn’t work, we must also dispatch it on the same queue!
    [[[CSComScore core] taskExecutor] execute:^{
        const SEL selectors[] = {
            @selector(appName),
            @selector(pixelURL),
            @selector(publisherSecret),
            @selector(customerC2),
            @selector(version),
            @selector(labels)
        };
        
        NSMutableString *message = [NSMutableString new];
        for (NSUInteger i = 0; i < sizeof(selectors) / sizeof(selectors[0]); i++) {
            SEL selector = selectors[i];
            [message appendFormat:@"%@: %@\n", NSStringFromSelector(selector), [CSComScore performSelector:selector]];
        }
        [message deleteCharactersInRange:NSMakeRange(message.length - 1, 1)];
        SRGAnalyticsLogDebug(@"%@", message);
    } background:YES];
}

#pragma mark - Notifications

- (void)comScoreRequestDidFinish:(NSNotification *)notification
{
    NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
    NSUInteger maxKeyLength = [[[labels allKeys] valueForKeyPath:@"@max.length"] unsignedIntegerValue];
    
    NSMutableString *dictionaryRepresentation = [NSMutableString new];
    for (NSString *key in [[labels allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        [dictionaryRepresentation appendFormat:@"%@ = %@\n", [key stringByPaddingToLength:maxKeyLength withString:@" " startingAtIndex:0], labels[key]];
    }
    
    NSString *ns_st_ev = labels[@"ns_st_ev"];
    NSString *ns_ap_ev = labels[@"ns_ap_ev"];
    NSString *type = labels[@"ns_st_ty"];
    NSString *typeSymbol = @"\U00002753"; // BLACK QUESTION MARK ORNAMENT
    
    if ([type.lowercaseString isEqual:@"audio"]) {
        typeSymbol = @"\U0001F4FB"; // RADIO
    }
    else if ([type.lowercaseString isEqual:@"video"]) {
        typeSymbol = @"\U0001F4FA"; // TELEVISION
    }
    
    if ([labels[@"ns_st_li"] boolValue]) {
        typeSymbol = [typeSymbol stringByAppendingString:@"\U0001F6A8"];
    }
    
    NSString *event = ns_st_ev ? [typeSymbol stringByAppendingFormat:@" %@", ns_st_ev] : ns_ap_ev;
    NSString *name = ns_st_ev ? [NSString stringWithFormat:@"%@ / %@", labels[@"ns_st_pl"], labels[@"ns_st_ep"]] : labels[@"name"];
    SRGAnalyticsLogInfo(@"%@ > %@", event, name);
    
    SRGAnalyticsLogDebug(@"Comscore %@ event sent:\n%@", labels[@"ns_type"], dictionaryRepresentation);
}

@end
