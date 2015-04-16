//
//  Created by Frédéric Humbert-Droz on 15/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAnalyticsTracker.h"
#import "RTSAnalyticsStreamTracker_private.h"

#import <RTSMediaPlayer/RTSMediaPlayerController.h>
#import "RTSMediaPlayerControllerStreamSenseTracker_private.h"

#import <comScore-iOS-SDK/CSComScore.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface RTSAnalyticsStreamTracker ()
@property (nonatomic, weak) id<RTSAnalyticsMediaPlayerDataSource> dataSource;
@property (nonatomic, strong) NSMutableDictionary *streamsenseTrackers;
@property (nonatomic, strong) NSString *virtualSite;
@end

@implementation RTSAnalyticsStreamTracker

+ (instancetype) sharedTracker
{
	static RTSAnalyticsStreamTracker *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[[self class] alloc] init_custom_RTSAnalyticsStreamTracker];
	});
	return sharedInstance;
}

- (id)init_custom_RTSAnalyticsStreamTracker
{
	if (!(self = [super init]))
		return nil;
	
	_streamsenseTrackers = [NSMutableDictionary new];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startStreamMeasurementForVirtualSite:(NSString *)virtualSite mediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource
{
	_dataSource = dataSource;
	_virtualSite = virtualSite;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackStateDidChange:) name:RTSMediaPlayerPlaybackStateDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackDidFail:) name:RTSMediaPlayerPlaybackDidFailNotification object:nil];
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
			[self notifyStreamTrackerEvent:CSStreamSenseBuffer mediaPlayer:mediaPlayerController];
			break;
			
		case RTSMediaPlaybackStateReady:
			break;
			
		case RTSMediaPlaybackStateStalled:
			[self notifyStreamTrackerEvent:CSStreamSenseBuffer mediaPlayer:mediaPlayerController];
			break;
			
		case RTSMediaPlaybackStatePlaying:
			[self notifyStreamTrackerEvent:CSStreamSensePlay mediaPlayer:mediaPlayerController];
			break;
			
		case RTSMediaPlaybackStatePaused:
			[self notifyStreamTrackerEvent:CSStreamSensePause mediaPlayer:mediaPlayerController];
			break;
			
		case RTSMediaPlaybackStateEnded:
			[self notifyStreamTrackerEvent:CSStreamSenseEnd mediaPlayer:mediaPlayerController];
			break;
			
		case RTSMediaPlaybackStateIdle:
			[self notifyStreamTrackerEvent:CSStreamSenseEnd mediaPlayer:mediaPlayerController];
			[self removeStreamTrackerForMediaPlayer:mediaPlayerController];
			break;
	}
}

- (void)mediaPlayerPlaybackDidFail:(NSNotification *)notification
{
	RTSMediaPlayerController *mediaPlayerController = notification.object;
	[self removeStreamTrackerForMediaPlayer:mediaPlayerController];
}

- (void) notifyStreamTrackerEvent:(CSStreamSenseEventType)eventType mediaPlayer:(RTSMediaPlayerController *)mediaPlayerController
{
	DDLogVerbose(@"Notify stream tracker event %@ for media identifier `%@`", @(eventType), mediaPlayerController.identifier);
	
	RTSMediaPlayerControllerStreamSenseTracker *tracker = self.streamsenseTrackers[mediaPlayerController.identifier];
	if (!tracker) {
		
		DDLogVerbose(@"Create a new stream tracker for media identifier `%@`", mediaPlayerController.identifier);
		
		tracker = [[RTSMediaPlayerControllerStreamSenseTracker alloc] initWithPlayer:mediaPlayerController dataSource:self.dataSource virtualSite:self.virtualSite];
		self.streamsenseTrackers[mediaPlayerController.identifier] = tracker;
		
		[CSComScore onUxActive];
	}
	[tracker notify:eventType];
}

- (void) removeStreamTrackerForMediaPlayer:(RTSMediaPlayerController *)mediaPlayerController
{
	DDLogVerbose(@"Delete stream tracker for media identifier `%@`", mediaPlayerController.identifier);
	[self.streamsenseTrackers removeObjectForKey:mediaPlayerController.identifier];
	[CSComScore onUxInactive];
}


@end
