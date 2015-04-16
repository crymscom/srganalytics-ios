//
//  Created by Cédric Foellmi on 25/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAnalyticsTracker.h"

#import "RTSAnalyticsNetmetrixTracker_private.h"

#import "NSString+RTSAnalytics.h"
#import "NSDictionary+RTSAnalytics_private.h"

#import <comScore-iOS-SDK/CSComScore.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

#if __has_include("RTSAnalyticsMediaPlayer.h")
#define RTSAnalyticsMediaPlayerIncluded
#import "RTSAnalyticsMediaPlayer.h"
#import "RTSAnalyticsStreamTracker_private.h"
#endif

@interface CSTaskExecutor : NSObject
- (void)execute:(void(^)(void))block background:(BOOL)background;
@end

@interface CSCore : NSObject
- (CSTaskExecutor *)taskExecutor;
@end

@interface RTSAnalyticsTracker ()
@property (nonatomic, strong) RTSAnalyticsNetmetrixTracker *netmetrixTracker;
@property (nonatomic, weak) id<RTSAnalyticsPageViewDataSource> lastPageViewDataSource;
@property (nonatomic, assign) SSRBusinessUnit businessUnit;
@end

@implementation RTSAnalyticsTracker

+ (instancetype) sharedTracker
{
	static RTSAnalyticsTracker *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[[self class] alloc] init_custom_RTSAnalyticsTracker];
	});
	return sharedInstance;
}

- (id)init_custom_RTSAnalyticsTracker
{
    self = [super init];
    if (self) {
		self.production = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
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
	//FIXME: check if from push
	[self trackPageViewTitle:@"comingToForeground" levels:@[ @"app", @"event" ]];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	if (!self.lastPageViewDataSource) {
		return;
	}
	
	[self trackPageViewForDataSource:self.lastPageViewDataSource];
}

#pragma mark - Accessors

- (NSArray *) businessUnits
{
	return @[ @"SRF", @"RTS", @"RSI", @"RTR", @"SWI" ];
}

- (NSString *) businessUnitName
{
	return self.businessUnits[self.businessUnit];
}

- (NSString *) comscoreVSite
{
	if (_comscoreVSite.length == 0)
		_comscoreVSite = [self infoDictionaryValueForKey:@"ComscoreVirtualSite"];
	
	return _comscoreVSite;
}

- (NSString *) netmetrixAppId
{
	if (_netmetrixAppId.length == 0)
		_netmetrixAppId = [self infoDictionaryValueForKey:@"NetmetrixAppID"];
	
	return _netmetrixAppId;
}

- (BOOL) production
{
	return _production;
}

- (NSString *)infoDictionaryValueForKey:(NSString *)key
{
	NSDictionary *analyticsInfoDictionary = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"RTSAnalytics"];
	return [analyticsInfoDictionary objectForKey:key];
}

#pragma mark - PageView tracking

#ifdef RTSAnalyticsMediaPlayerIncluded
- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit mediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource
{
	_businessUnit = businessUnit;
	
	[self startComscoreTracker];
	[self startNetmetrixTracker];
	
	NSString *streamSenseVirtualSite = self.production ? [NSString stringWithFormat:@"%@-v", self.businessUnitName.lowercaseString] : nil;
	[[RTSAnalyticsStreamTracker sharedTracker] startStreamMeasurementForVirtualSite:streamSenseVirtualSite mediaDataSource:dataSource];
}
#else
- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit
{
	_businessUnit = businessUnit;
	
	[self startComscoreTracker];
	[self startNetmetrixTracker];
}
#endif

- (void)startComscoreTracker
{
	NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
	
	NSString *appName = [[mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"] stringByAppendingString:@" iOS"];
	NSString *appLanguage = [[mainBundle preferredLocalizations] firstObject] ?: @"fr";
	NSString *appVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	
	NSAssert(self.comscoreVSite.length > 0, @"You MUST set `comscoreVSite` property, or define `RTSAnalytics>ComscoreVirtualSite` key in your app Info.plist");

	[CSComScore setAppContext];
	[CSComScore setCustomerC2:@"6036016"];
	[CSComScore setPublisherSecret:@"b19346c7cb5e521845fb032be24b0154"];
	[CSComScore enableAutoUpdate:60 foregroundOnly:NO]; //60 is the Comscore default interval value
	[CSComScore setLabels:@{ @"ns_ap_an": appName,
			  @"ns_ap_lang" : [NSLocale canonicalLanguageIdentifierFromString:appLanguage],
			  @"ns_ap_ver": appVersion,
			  @"srg_unit": self.businessUnitName,
			  @"srg_ap_push": @"0",
			  @"ns_site": @"mainsite",
			  @"ns_vsite": self.comscoreVSite}];
}

- (void)startNetmetrixTracker
{
	NSAssert(self.netmetrixAppId.length > 0, @"You MUST set `netmetrixAppId` property or define `RTSAnalytics>NetmetrixAppID` key in your app Info.plist");
	self.netmetrixTracker = [[RTSAnalyticsNetmetrixTracker alloc] initWithAppID:self.netmetrixAppId businessUnit:self.businessUnit production:self.production];
}

#pragma mark - PageView tracking

- (void)trackPageViewForDataSource:(id<RTSAnalyticsPageViewDataSource>)dataSource
{
	_lastPageViewDataSource = dataSource;
	
    if (!dataSource) {
		return;
    }
	
	NSString *title = [dataSource pageViewTitle];
	NSArray *levels = nil;
	
	if ([dataSource respondsToSelector:@selector(pageViewLevels)])
		levels = [dataSource pageViewLevels];
	
	NSDictionary *customLabels = nil;
	if ([dataSource respondsToSelector:@selector(pageViewCustomLabels)]) {
		customLabels = [dataSource pageViewCustomLabels];
	}
	
	//FIXME : detect from notification
	[self trackPageViewTitle:title levels:levels customLabels:customLabels fromPushNotification:NO];
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
			NSString *levelKey = [NSString stringWithFormat:@"srg_n%ld", idx+1];
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

@end
