//
//  Created by Cédric Foellmi on 25/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAnalyticsTracker.h"

#import <RTSMediaPlayer/RTSMediaPlayerController.h>
#import "RTSMediaPlayerControllerStreamSenseTracker.h"
#import "RTSAnalyticsNetmetrixTracker.h"

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
@property (nonatomic, strong) RTSAnalyticsNetmetrixTracker *netmetrixTracker;
@property (nonatomic, strong) NSMutableDictionary *streamsenseTrackers;
@property (nonatomic, weak) id<RTSAnalyticsPageViewDataSource> lastPageViewDataSource;
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
        _streamsenseTrackers = [NSMutableDictionary new];
        
        [CSComScore setAppContext];
        [CSComScore setCustomerC2:@"6036016"];
        [CSComScore setPublisherSecret:@"b19346c7cb5e521845fb032be24b0154"];
        [CSComScore enableAutoUpdate:60 foregroundOnly:NO]; //60 is the Comscore default interval value
        [CSComScore setLabels:[self comScoreGlobalLabels]];
        
        NSString *netmetrixAppID = [self infoDictionnaryValueForKey:@"NetmetrixAppID"];
        NSString *netmetrixDomain = [self infoDictionnaryValueForKey:@"NetmetrixDomain"];
        if (netmetrixAppID.length > 0) {
            self.netmetrixTracker = [[RTSAnalyticsNetmetrixTracker alloc] initWithAppID:netmetrixAppID domain:netmetrixDomain ?: [self businessUnit]];
        }
        else {
            DDLogInfo(@"Netmetrix has not been initialized due to missing appId. This is the normal behaviour while developping/testing apps");
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackStateDidChange:) name:RTSMediaPlayerPlaybackStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackDidFail:) name:RTSMediaPlayerPlaybackDidFailNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startTrackingWithMediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource
{
	_dataSource = dataSource;
}

- (NSDictionary *)comScoreGlobalLabels
{
	NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
	
	NSString *appName = [[mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"] stringByAppendingString:@" iOS"];
	NSString *appLanguage = [[mainBundle preferredLocalizations] firstObject] ?: @"fr";
	NSString *appVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	
	NSString *comScoreVirtualSite = [self infoDictionnaryValueForKey:@"ComscoreVirtualSite"];
	NSAssert(comScoreVirtualSite.length > 0, @"You MUST define `RTSAnalytics>ComscoreVirtualSite` key in your app Info.plist");
	
	return @{ @"ns_ap_an": appName,
			  @"ns_ap_lang" : [NSLocale canonicalLanguageIdentifierFromString:appLanguage],
			  @"ns_ap_ver": appVersion,
			  @"srg_unit": [self businessUnit].uppercaseString,
			  @"srg_ap_push": @"0",
			  @"ns_site": @"mainsite",
			  @"ns_vsite": comScoreVirtualSite};
}

- (NSString *)infoDictionnaryValueForKey:(NSString *)key
{
	NSDictionary *analyticsInfoDictionnary = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"RTSAnalytics"];
	return [analyticsInfoDictionnary objectForKey:key];
}

// TODO: This must not be hardcoded into plist, as we want to be able to play with it.
// Moreover, retrieving like the line below is very fragile.
- (NSString *)businessUnit
{
	return [[[NSBundle bundleForClass:[self class]].bundleIdentifier componentsSeparatedByString:@"."][1] lowercaseString];
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
	
	title = [title comScoreFormattedString];
	[labels safeSetValue:(title.length > 0 ? title : @"Untitled") forKey:@"srg_title"];
	
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
	[labels safeSetValue:[NSString stringWithFormat:@"%@.%@", category, title] forKey:@"name"];
	
	[customLabels enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[labels safeSetValue:[obj description] forKey:[key description]];
	}];
	
	[CSComScore viewWithLabels:labels];
	
	[self.netmetrixTracker trackView];
}

#pragma mark - Stream tracking

- (void)mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
    if (!_dataSource) {
        // We haven't started yet.
        return;
    }
    
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

- (void)createTrackerForMediaPlayer:(RTSMediaPlayerController *)mediaPlayerController
{
	DDLogVerbose(@"Create a new stream tracker for media identifier `%@`", mediaPlayerController.identifier);
	
	RTSMediaPlayerControllerStreamSenseTracker *tracker = [[RTSMediaPlayerControllerStreamSenseTracker alloc] initWithPlayer:mediaPlayerController dataSource:self.dataSource];
	self.streamsenseTrackers[mediaPlayerController.identifier] = tracker;
	
	[self notifyTracker:CSStreamSenseBuffer mediaPlayer:mediaPlayerController];
	[self updateComscoreUxStatus];
}

- (void) notifyTracker:(CSStreamSenseEventType)eventType mediaPlayer:(RTSMediaPlayerController *)mediaPlayerController
{
	DDLogVerbose(@"Notify stream tracker event %@ for media identifier `%@`", @(eventType), mediaPlayerController.identifier);
	
	RTSMediaPlayerControllerStreamSenseTracker *tracker = self.streamsenseTrackers[mediaPlayerController.identifier];
	[tracker notify:eventType];
}

- (void) removeTrackerForMediaPlayer:(RTSMediaPlayerController *)mediaPlayerController
{
	DDLogVerbose(@"Delete stream tracker for media identifier `%@`", mediaPlayerController.identifier);
	
	[self notifyTracker:CSStreamSenseEnd mediaPlayer:mediaPlayerController];
	[self.streamsenseTrackers removeObjectForKey:mediaPlayerController.identifier];
	[self updateComscoreUxStatus];
}

- (void) updateComscoreUxStatus
{
	BOOL areSomeMediaPlaying = self.streamsenseTrackers.count > 0;
	if (areSomeMediaPlaying) {
		[CSComScore onUxActive];
	}
    else {
		[CSComScore onUxInactive];
	}
}

@end
