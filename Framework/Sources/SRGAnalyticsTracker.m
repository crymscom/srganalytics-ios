//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

#import "SRGAnalyticsNetmetrixTracker.h"

#import "NSString+SRGAnalytics.h"
#import "NSDictionary+SRGAnalytics.h"
#import "SRGAnalyticsTracker+Logging.h"
#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsPageViewDataSource.h"

#import <ComScore/CSComScore.h>
#import <UIKit/UIKit.h>

NSString * const SRGAnalyticsNetmetrixRequestDidFinishNotification = @"SRGAnalyticsNetmetrixRequestDidFinish";
NSString * const SRGAnalyticsNetmetrixRequestSuccessUserInfoKey = @"SRGAnalyticsNetmetrixSuccess";
NSString * const SRGAnalyticsNetmetrixRequestErrorUserInfoKey = @"SRGAnalyticsNetmetrixError";
NSString * const SRGAnalyticsNetmetrixRequestResponseUserInfoKey = @"SRGAnalyticsNetmetrixResponse";

@interface SRGAnalyticsTracker () {
@private
    BOOL _debugMode;
}
@property (nonatomic, strong) SRGAnalyticsNetmetrixTracker *netmetrixTracker;
@property (nonatomic, weak) id<SRGAnalyticsPageViewDataSource> lastPageViewDataSource;
@property (nonatomic, assign) SSRBusinessUnit businessUnit;
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

+ (NSBundle *)bundle
{
    return [NSBundle mainBundle];
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
	[self trackPageViewForDataSource:self.lastPageViewDataSource];
}

#pragma mark - Accessors

- (NSArray *) businessUnits
{
	return @[ @"SRF", @"RTS", @"RSI", @"RTR", @"SWI" ];
}

- (NSString *) businessUnitIdentifier:(SSRBusinessUnit)businessUnit
{
	return [self.businessUnits[businessUnit] lowercaseString];
}

- (SSRBusinessUnit) businessUnitForIdentifier:(NSString *)buIdentifier
{
	NSUInteger index = [self.businessUnits indexOfObject:buIdentifier.uppercaseString];
	NSAssert(index != NSNotFound, @"Business unit not found with identifier '%@'", buIdentifier);
	return (SSRBusinessUnit)index;
}

- (NSString *) comscoreVSite
{
	return [self infoDictionaryValueForKey:@"ComscoreVirtualSite"];
}

- (NSString *) netmetrixAppId
{
	return [self infoDictionaryValueForKey:@"NetmetrixAppID"];
}

- (NSString *)infoDictionaryValueForKey:(NSString *)key
{
	NSDictionary *analyticsInfoDictionary = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SRGAnalytics"];
	return [analyticsInfoDictionary objectForKey:key];
}

#pragma mark - PageView tracking

- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit
{
    [self startTrackingForBusinessUnit:businessUnit inDebugMode:NO];
}

- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit inDebugMode:(BOOL)debugMode
{
    _businessUnit = businessUnit;
    _debugMode = debugMode;
    
    [self startComscoreTracker];
    [self startNetmetrixTracker];
}

- (void)startComscoreTracker
{
	NSAssert(self.comscoreVSite.length > 0, @"You MUST define `SRGAnalytics>ComscoreVirtualSite` key in your app Info.plist");
	
	[CSComScore setAppContext];
	[CSComScore setCustomerC2:@"6036016"];
	[CSComScore setPublisherSecret:@"b19346c7cb5e521845fb032be24b0154"];
	[CSComScore enableAutoUpdate:60 foregroundOnly:NO]; //60 is the Comscore default interval value
	NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
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
	NSString *appLanguage = [[mainBundle preferredLocalizations] firstObject] ?: @"fr";
    NSString *appVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    NSMutableDictionary *globalLabels = [@{ @"ns_ap_an": appName,
                                            @"ns_ap_lang" : [NSLocale canonicalLanguageIdentifierFromString:appLanguage],
                                            @"ns_ap_ver": appVersion,
                                            @"srg_unit": [self businessUnitIdentifier:self.businessUnit].uppercaseString,
                                            @"srg_ap_push": @"0",
                                            @"ns_site": @"mainsite", // MGubler 17-Nov-2015: This 'mainsite' is a constant value. If wrong, everything is screwed.
                                            @"ns_vsite": self.comscoreVSite} mutableCopy]; // MGubler 17-Nov-2015: 'vsite' is associated with the app. It is created by comScore itself.
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
	NSAssert(self.netmetrixAppId.length > 0, @"You MUST define `SRGAnalytics>NetmetrixAppID` key in your app Info.plist");
	self.netmetrixTracker = [[SRGAnalyticsNetmetrixTracker alloc] initWithAppID:self.netmetrixAppId businessUnit:self.businessUnit];
}

#pragma mark - PageView tracking

- (void)trackPageViewForDataSource:(id<SRGAnalyticsPageViewDataSource>)dataSource
{
	_lastPageViewDataSource = dataSource;
	
    if (!dataSource)
		return;
	
	NSString *title = [dataSource pageViewTitle];
	NSArray *levels = nil;
	
	if ([dataSource respondsToSelector:@selector(pageViewLevels)])
		levels = [dataSource pageViewLevels];
	
	NSDictionary *customLabels = nil;
	if ([dataSource respondsToSelector:@selector(pageViewCustomLabels)]) {
		customLabels = [dataSource pageViewCustomLabels];
	}
	
	BOOL fromPushNotification = NO;
	if ([dataSource respondsToSelector:@selector(pageViewFromPushNotification)])
		fromPushNotification = [dataSource pageViewFromPushNotification];
	
	[self trackPageViewTitle:title levels:levels customLabels:customLabels fromPushNotification:fromPushNotification];
}

- (void)trackPageViewTitle:(NSString *)title levels:(NSArray *)levels
{
	[self trackPageViewTitle:title levels:levels customLabels:nil fromPushNotification:NO];
}

- (void)trackPageViewTitle:(NSString *)title levels:(NSArray *)levels customLabels:(NSDictionary *)customLabels fromPushNotification:(BOOL)fromPush
{
	NSMutableDictionary *labels = [NSMutableDictionary dictionary];
	
	title = title.length > 0 ? [title comScoreTitleFormattedString] : @"untitled";
	[labels safeSetValue:title forKey:@"srg_title"];
	[labels safeSetValue:@(fromPush) forKey:@"srg_ap_push"];
	
	NSString *category = @"app";
	
	if (!levels)
	{
		[labels safeSetValue:category forKey:@"srg_n1"];
	}
	else if (levels.count > 0)
	{
		__block NSMutableString *levelsConcatenation = [NSMutableString new];
		[levels enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL *stop) {
			NSString *levelKey = [NSString stringWithFormat:@"srg_n%tu", idx+1];
			NSString *levelValue = [[value description] comScoreFormattedString];
			
			if (idx<10) {
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
	[labels safeSetValue:[NSString stringWithFormat:@"%@.%@", category, [title comScoreFormattedString]] forKey:@"name"];
	
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
    
    title = title.length > 0 ? [title comScoreTitleFormattedString] : @"untitled";
    [labels safeSetValue:title forKey:@"srg_title"];
    
    [customLabels enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [labels safeSetValue:[obj description] forKey:[key description]];
    }];
    
    [CSComScore hiddenWithLabels:labels];
}

@end
