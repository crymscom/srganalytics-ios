//
//  Created by Cédric Foellmi on 25/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAnalyticsTracker.h"

#import <RTSMediaPlayer/RTSMediaPlayerController.h>
#import "RTSMediaPlayerControllerStreamSenseTracker.h"

#import "NSString+RTSAnalyticsUtils.h"
#import "NSDictionary+RTSAnalyticsUtils.h"

#import <comScore-iOS-SDK/CSComScore.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface CSTaskExecutor : NSObject
- (void)execute:(void(^)(void))block background:(BOOL)background;
@end

@interface CSCore : NSObject
- (CSTaskExecutor *)taskExecutor;
@end

@interface RTSAnalyticsTracker ()
@property (nonatomic, weak) id<RTSAnalyticsMediaPlayerDataSource> dataSource;
@property (nonatomic, strong) NSMutableDictionary *streamsenseTrackers;
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
	_streamsenseTrackers = [NSMutableDictionary new];
	
	[CSComScore onUxActive];
	[CSComScore setCustomerC2:@"6036016"];
	[CSComScore setPublisherSecret:@"b19346c7cb5e521845fb032be24b0154"];
	[CSComScore setLabels:[self comScoreGlobalLabels]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackStateDidChange:) name:RTSMediaPlayerPlaybackStateDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackDidFail:) name:RTSMediaPlayerPlaybackDidFailNotification object:nil];
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

#pragma mark - Notifications

- (void) applicationWillEnterForeground:(NSNotification *)notification
{
	//FIXME: check if from push
	[self trackPageViewTitle:@"comingToForeground" levels:@[ @"app", @"event" ] fromPushNotification:NO];
}

#pragma mark - PageView tracking


- (void)trackPageViewTitle:(NSString *)title levels:(NSArray *)levels
{
	[self trackPageViewTitle:title levels:levels fromPushNotification:NO];
}

- (void)trackPageViewTitle:(NSString *)title levels:(NSArray *)levels fromPushNotification:(BOOL)fromPush
{
	NSMutableDictionary *labels = [NSMutableDictionary dictionary];
	
	title = [title comScoreFormattedString];
	
	if (title.length == 0) {
		title = @"Untitled";
	}
	
	[labels safeSetValue:title forKey:@"srg_title"];
	
	[labels safeSetValue:@(fromPush) forKey:@"srg_ap_push"];
	
	__block NSMutableString *category = [NSMutableString new];
	if (levels.count == 0)
	{
		[category appendString:@"app"];
		[labels safeSetValue:[category copy] forKey:@"srg_n1"];
	}
	else
	{
		[levels enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL *stop) {
			NSLog(@"%@, %ld", value, idx);
			
			NSString *levelKey = [NSString stringWithFormat:@"srg_n%ld", idx+1];
			NSString *levelValue = [[value description] comScoreFormattedString];
			
			if (idx<10) {
				[labels safeSetValue:levelValue forKey:levelKey];
			}
			
			if (category.length > 0) {
				[category appendString:@"."];
			}
			[category appendString:levelValue];
		}];
	}
	
	[labels safeSetValue:category forKey:@"category"];
	[labels safeSetValue:[NSString stringWithFormat:@"%@.%@", category, title] forKey:@"name"];
	
	[CSComScore viewWithLabels:labels];
}

#pragma mark - Stream tracking

- (void)mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	RTSMediaPlayerController *mediaPlayerController = notification.object;
	switch (mediaPlayerController.playbackState)
	{
		case RTSMediaPlaybackStatePreparing:
			[self createTrackerForMediaPlayer:mediaPlayerController];
			break;
			
		case RTSMediaPlaybackStateReady:
			break;
			
		case RTSMediaPlaybackStateStalled:
			[self notifyTracker:CSStreamSenseBuffer mediaPlayer:mediaPlayerController];
			break;
			
		case RTSMediaPlaybackStatePlaying:
			[self notifyTracker:CSStreamSensePlay mediaPlayer:mediaPlayerController];
			break;
			
		case RTSMediaPlaybackStatePaused:
			[self notifyTracker:CSStreamSensePause mediaPlayer:mediaPlayerController];
			break;
			
		case RTSMediaPlaybackStateEnded:
		case RTSMediaPlaybackStateIdle:
			[self removeTrackerForMediaPlayer:mediaPlayerController];
			break;
	}
}

- (void)mediaPlayerPlaybackDidFail:(NSNotification *)notification
{
	RTSMediaPlayerController *mediaPlayerController = notification.object;
	[self removeTrackerForMediaPlayer:mediaPlayerController];
}

- (void) createTrackerForMediaPlayer:(RTSMediaPlayerController *)mediaPlayerController
{
	DDLogVerbose(@"Create a new tracker for media %@", mediaPlayerController.identifier);
	
	RTSMediaPlayerControllerStreamSenseTracker *mediaPlayerControllerStreamSensePlugin = [[RTSMediaPlayerControllerStreamSenseTracker alloc] initWithPlayer:mediaPlayerController dataSource:self.dataSource];
	self.streamsenseTrackers[mediaPlayerController.identifier] = mediaPlayerControllerStreamSensePlugin;
	
	[self notifyTracker:CSStreamSenseBuffer mediaPlayer:mediaPlayerController];
}

- (void) notifyTracker:(CSStreamSenseEventType)eventType mediaPlayer:(RTSMediaPlayerController *)mediaPlayerController
{
	DDLogVerbose(@"Notify tracker event %@ for media %@", @(eventType), mediaPlayerController.identifier);
	
	RTSMediaPlayerControllerStreamSenseTracker *mediaPlayerControllerStreamSensePlugin = self.streamsenseTrackers[mediaPlayerController.identifier];
	[mediaPlayerControllerStreamSensePlugin notify:eventType];
}

- (void) removeTrackerForMediaPlayer:(RTSMediaPlayerController *)mediaPlayerController
{
	DDLogVerbose(@"Delete tracker for media %@", mediaPlayerController.identifier);
	
	[self notifyTracker:CSStreamSenseEnd mediaPlayer:mediaPlayerController];
	[self.streamsenseTrackers removeObjectForKey:mediaPlayerController.identifier];
}

@end
