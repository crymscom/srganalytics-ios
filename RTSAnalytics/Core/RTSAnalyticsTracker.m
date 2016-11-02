//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSAnalyticsTracker.h"

#import "RTSAnalyticsNetmetrixTracker_private.h"

#import "NSString+RTSAnalytics.h"
#import "NSDictionary+RTSAnalytics.h"
#import "RTSAnalyticsTracker+Logging_private.h"
#import "RTSAnalyticsLogger_private.h"
#import "RTSAnalyticsPageViewDataSource.h"

#import <ComScore/CSComScore.h>

#if __has_include("RTSAnalyticsMediaPlayer.h")
#define RTSAnalyticsMediaPlayerIncluded
#import "RTSAnalyticsMediaPlayer.h"
#import "RTSMediaPlayerControllerTracker_private.h"
#endif

@interface RTSAnalyticsTracker () {
@private
    BOOL _debugMode;
}
@property (nonatomic, strong) RTSAnalyticsNetmetrixTracker *netmetrixTracker;
@property (nonatomic, weak) id<RTSAnalyticsPageViewDataSource> lastPageViewDataSource;
@property (nonatomic, assign) SSRBusinessUnit businessUnit;
@end

@implementation RTSAnalyticsTracker

+ (instancetype)sharedTracker
{
	static RTSAnalyticsTracker *sharedInstance = nil;
	static dispatch_once_t RTSAnalyticsTracker_onceToken;
	dispatch_once(&RTSAnalyticsTracker_onceToken, ^{
		sharedInstance = [[[self class] alloc] init_custom_RTSAnalyticsTracker];
	});
	return sharedInstance;
}

+ (NSBundle *)bundle
{
#if defined(TEST) || defined(POD_CONFIGURATION_TEST)
    return [NSBundle bundleForClass:[self class]];
#else
    return [NSBundle mainBundle];
#endif
}

- (id)init_custom_RTSAnalyticsTracker
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

- (NSString *) streamSenseVSite
{
    return [self infoDictionaryValueForKey:@"StreamSenseVirtualSite"] ?: self.comscoreVSite;
}

- (NSString *) netmetrixAppId
{
	return [self infoDictionaryValueForKey:@"NetmetrixAppID"];
}

- (NSString *)infoDictionaryValueForKey:(NSString *)key
{
	NSDictionary *analyticsInfoDictionary = [[RTSAnalyticsTracker bundle] objectForInfoDictionaryKey:@"RTSAnalytics"];
	return [analyticsInfoDictionary objectForKey:key];
}

#pragma mark - PageView tracking

#ifdef RTSAnalyticsMediaPlayerIncluded

- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit
                     mediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource

{
    [self startTrackingForBusinessUnit:businessUnit mediaDataSource:dataSource inDebugMode:NO];
}

- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit
                     mediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource
                         inDebugMode:(BOOL)debugMode
{
    [self startTrackingForBusinessUnit:businessUnit inDebugMode:debugMode];
    
    NSAssert(self.streamSenseVSite.length > 0, @"You MUST define `RTSAnalytics>ComscoreVirtualSite` key in your app Info.plist, optionally overridden with `RTSAnalytics>StreamSenseVirtualSite`");
    [[RTSMediaPlayerControllerTracker sharedTracker] startStreamMeasurementForVirtualSite:self.streamSenseVSite mediaDataSource:dataSource];
}

#endif

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
	NSAssert(self.comscoreVSite.length > 0, @"You MUST define `RTSAnalytics>ComscoreVirtualSite` key in your app Info.plist");
	
	[CSComScore setAppContext];
    [CSComScore setSecure:YES];
	[CSComScore setCustomerC2:@"6036016"];
	[CSComScore setPublisherSecret:@"b19346c7cb5e521845fb032be24b0154"];
	[CSComScore enableAutoUpdate:60 foregroundOnly:NO]; //60 is the Comscore default interval value
	NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (appName) {
		[CSComScore setAutoStartLabels:@{ @"name": appName }];
    }
	[CSComScore setLabels:[self comscoreGlobalLabels]];
	
	[self startLoggingInternalComScoreTasks];
    [self sendApplicationList];
}

#pragma mark Application list measurement

- (void)sendApplicationList
{
    // Tracks which SRG SSR applications are installed on the user device
    //
    // Specifications are available at: https://srfmmz.atlassian.net/wiki/display/INTFORSCHUNG/App+Overlapping+Measurement
    //
    // This measurement is not critical and is therefore performed only once the tracker starts. If it fails for some reason
    // (no network, for example), the measurement will be attempted again the next time the application is started
    NSURL *applicationListURL = [NSURL URLWithString:@"https://pastebin.com/raw/RnZYEWCA"];
    [[[NSURLSession sharedSession] dataTaskWithURL:applicationListURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            RTSAnalyticsLogError(@"The application list could not be retrieved. Reason: %@", error);
            return;
        }
        
        NSError *parseError = nil;
        id JSONObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (! JSONObject || ! [JSONObject isKindOfClass:[NSArray class]]) {
            RTSAnalyticsLogError(@"The application list format is incorrect");
            return;
        }
        NSArray<NSDictionary *> *applicationDictionaries = JSONObject;
        
        // Extract URL schemes and installed applications
        NSMutableSet<NSString *> *URLSchemes = [NSMutableSet set];
        NSMutableSet<NSString *> *installedApplications = [NSMutableSet set];
        for (NSDictionary *applicationDictionary in applicationDictionaries) {
            NSString *application = applicationDictionary[@"code"];
            NSString *URLScheme = applicationDictionary[@"ios"];
            
            if (URLScheme.length == 0 || ! application) {
                RTSAnalyticsLogWarning(@"URL scheme or application name missing in %@. Skipped", applicationDictionary);
                continue;
            }
            
            [URLSchemes addObject:URLScheme];
            
            NSString *URLString = [NSString stringWithFormat:@"%@://probe-for-srganalytics", URLScheme];
            if (! [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:URLString]]) {
                continue;
            }
            
            [installedApplications addObject:application];
        }
        
        // Since iOS 9, to be able to open a URL in another application (and thus to be able to test for URL scheme
        // support), the application must declare the schemes it supports via its Info.plist file (under the
        // `LSApplicationQueriesSchemes` key). If we are running on iOS 9 or above, check that the app list is consistent
        // with the remote list, and log an error if this is not the case
        NSArray<NSString *> *declaredURLSchemesArray = [NSBundle mainBundle].infoDictionary[@"LSApplicationQueriesSchemes"];
        NSSet<NSString *> *declaredURLSchemes = declaredURLSchemesArray ? [NSSet setWithArray:declaredURLSchemesArray] : [NSSet set];
        if (! [URLSchemes isSubsetOfSet:declaredURLSchemes]) {
            RTSAnalyticsLogError(@"The URL schemes declared in your application Info.plist file under the "
                                 "'LSApplicationQueriesSchemes' key must at list contain the scheme list available at "
                                 "https://pastebin.com/raw/RnZYEWCA (the schemes are found under the 'ios' key, or a script is available in the SRGAnalytics repository to collect it). Please "
                                 "update your Info.plist file to make this message disappear");
        }
        
        if (installedApplications.count == 0) {
            RTSAnalyticsLogWarning(@"No identified application installed. Nothing to be done");
            return;
        }
        
        NSArray *sortedInstalledApplications = [installedApplications.allObjects sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        NSDictionary *labels = @{ @"srg_evgroup" : @"Installed Apps",
                                  @"srg_evname" : [sortedInstalledApplications componentsJoinedByString:@","] };
        [CSComScore hiddenWithLabels:labels];
    }] resume];
}

- (NSDictionary *)comscoreGlobalLabels
{
	NSBundle *mainBundle = [RTSAnalyticsTracker bundle];
	
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
                                                                                           // Even if it is 'easy' to create a new one (for new/easier reports, or fixing wrong values),
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
	NSAssert(self.netmetrixAppId.length > 0, @"You MUST define `RTSAnalytics>NetmetrixAppID` key in your app Info.plist");
	self.netmetrixTracker = [[RTSAnalyticsNetmetrixTracker alloc] initWithAppID:self.netmetrixAppId businessUnit:self.businessUnit];
}

#pragma mark - PageView tracking

- (void)trackPageViewForDataSource:(id<RTSAnalyticsPageViewDataSource>)dataSource
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
