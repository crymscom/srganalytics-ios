//
//  Created by Cédric Foellmi on 25/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAnalyticsTracker.h"

#import <comScore-iOS-SDK/CSComScore.h>
#import <comScore-iOS-SDK/CSStreamSense.h>
#import <comScore-iOS-SDK/CSStreamSenseClip.h>
#import <comScore-iOS-SDK/CSStreamSensePlaylist.h>

@interface CSTaskExecutor : NSObject
- (void)execute:(void(^)(void))block background:(BOOL)background;
@end

@interface CSCore : NSObject
- (CSTaskExecutor *)taskExecutor;
@end

@interface RTSAnalyticsTracker ()
@property (nonatomic, weak) id<RTSAnalyticsMediaPlayerDataSource> dataSource;
@end

@implementation RTSAnalyticsTracker

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype) sharedTracker
{
	static RTSAnalyticsTracker *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[[self class] alloc] init];
	});
	return sharedInstance;
}

- (void)startTrackingWithMediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource
{
	_dataSource = dataSource;
	
	[CSComScore onUxActive];
	[CSComScore setCustomerC2:@"6036016"];
	[CSComScore setPublisherSecret:@"b19346c7cb5e521845fb032be24b0154"];
	[CSComScore setLabels:[self comScoreGlobalLabels]];
}

- (NSDictionary *)comScoreGlobalLabels
{
	NSBundle *mainBundle = [NSBundle mainBundle];
	
	NSString *appName = [[mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"] stringByAppendingString:@" iOS"];
	NSString *appLanguage = [[mainBundle preferredLocalizations] firstObject] ?: @"fr";
	NSString *appVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	
	NSString *businessUnit = [mainBundle.bundleIdentifier componentsSeparatedByString:@"."][1];
	NSDictionary *analyticsInfoDictionnary = [mainBundle objectForInfoDictionaryKey:@"RTSAnalytics"];
	NSString *comScoreVirtualSite = [analyticsInfoDictionnary objectForKey:@"ComscoreVirtualSite"];
	NSAssert(comScoreVirtualSite.length > 0, @"You MUST define `RTSAnalytics>ComscoreVirtualSite` key in your app plist");
	
	return @{ @"ns_ap_an": appName,
			  @"ns_ap_lang" : [NSLocale canonicalLanguageIdentifierFromString:appLanguage],
			  @"ns_ap_ver": appVersion,
			  @"srg_unit": businessUnit,
			  @"srg_ap_push": @"0",
			  @"ns_site": @"mainsite",
			  @"ns_vsite": comScoreVirtualSite};
}


@end
