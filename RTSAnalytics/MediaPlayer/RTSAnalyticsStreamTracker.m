//
//  Created by Frédéric Humbert-Droz on 15/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAnalyticsTracker.h"
#import "RTSAnalyticsStreamTracker_private.h"
#import "RTSAnalyticsLogger.h"

#import <RTSMediaPlayer/RTSMediaPlayerController.h>
#import <RTSMediaPlayer/RTSMediaSegmentsController.h>
#import "RTSMediaPlayerControllerStreamSenseTracker_private.h"

#import <comScore-iOS-SDK-RTS/CSComScore.h>

@interface RTSAnalyticsStreamTracker ()
@property (nonatomic, weak) id<RTSAnalyticsMediaPlayerDataSource> dataSource;
@property (nonatomic, weak) id<RTSAnalyticsMediaPlayerDelegate> mediaPlayerDelegate;

@property (nonatomic, strong) id segment;

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
    NSParameterAssert(virtualSite && dataSource);
    
    if (!_dataSource && !_virtualSite) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mediaPlayerPlaybackStateDidChange:)
                                                     name:RTSMediaPlayerPlaybackStateDidChangeNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mediaPlayerPlaybackSegmentsDidChange:)
                                                     name:RTSMediaPlaybackSegmentDidChangeNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mediaPlayerPlaybackDidFail:)
                                                     name:RTSMediaPlayerPlaybackDidFailNotification
                                                   object:nil];
    }
    
    _dataSource = dataSource;
    _virtualSite = virtualSite;
}

- (BOOL) shouldTrackMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	BOOL shouldTrackMediaPlayerController = YES;
	if ([self.mediaPlayerDelegate conformsToProtocol:@protocol(RTSAnalyticsMediaPlayerDelegate)])
		shouldTrackMediaPlayerController = [self.mediaPlayerDelegate shouldTrackMediaWithIdentifier:mediaPlayerController.identifier];
	
	return shouldTrackMediaPlayerController;
}



#pragma mark - Notifications

- (void)mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	if (!_dataSource) {
		// We haven't started yet.
		return;
	}
	
	RTSMediaPlayerController *mediaPlayerController = notification.object;
	if ([self shouldTrackMediaPlayerController:mediaPlayerController])
	{
		switch (mediaPlayerController.playbackState) {
			case RTSMediaPlaybackStatePreparing:
				[self notifyStreamTrackerEvent:CSStreamSenseBuffer mediaPlayer:mediaPlayerController segment:self.segment];
				break;
				
			case RTSMediaPlaybackStateReady:
				break;
				
			case RTSMediaPlaybackStateStalled:
				[self notifyStreamTrackerEvent:CSStreamSenseBuffer mediaPlayer:mediaPlayerController segment:self.segment];
				break;
				
			case RTSMediaPlaybackStatePlaying:
				[self notifyStreamTrackerEvent:CSStreamSensePlay mediaPlayer:mediaPlayerController segment:self.segment];
				break;
				
			case RTSMediaPlaybackStatePaused:
            case RTSMediaPlaybackStateSeeking:
				[self notifyStreamTrackerEvent:CSStreamSensePause mediaPlayer:mediaPlayerController segment:self.segment];
				break;
				
			case RTSMediaPlaybackStateEnded:
				[self notifyStreamTrackerEvent:CSStreamSenseEnd mediaPlayer:mediaPlayerController segment:self.segment];
				break;
				
			case RTSMediaPlaybackStateIdle:
				[self stopTrackingMediaPlayerController:mediaPlayerController];
				break;
		}
	}
	else if (self.streamsenseTrackers[mediaPlayerController.identifier]) {
		[self stopTrackingMediaPlayerController:mediaPlayerController];
	}
}

- (void)mediaPlayerPlaybackSegmentsDidChange:(NSNotification *)notification
{
    RTSMediaSegmentsController *segmentsController = notification.object;
    NSInteger value = [notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue];
    BOOL wasUserSelected = [notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue];
    id previousSegment = notification.userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey];
    self.segment = notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey];

    // According to its implementation, Comscore only sends an event if different from the previously sent one. We
    // are therefore required to send a pause followed by a play when a segment end is detected (in which case
    // playback continues with another segment or with the full-length). Segment information is sent iff the segment
    // was selected by the user
    switch (value) {
        case RTSMediaPlaybackSegmentStart:
            [self notifyStreamTrackerEvent:CSStreamSensePlay
                               mediaPlayer:segmentsController.playerController
                                   segment:wasUserSelected ? self.segment : nil];
            break;

        case RTSMediaPlaybackSegmentSwitch: {
            [self notifyStreamTrackerEvent:CSStreamSensePause
                               mediaPlayer:segmentsController.playerController
                                   segment:previousSegment];
            [self notifyStreamTrackerEvent:CSStreamSensePlay
                               mediaPlayer:segmentsController.playerController
                                   segment:wasUserSelected ? self.segment : nil];
            break;
        }
            
        case RTSMediaPlaybackSegmentEnd: {
            [self notifyStreamTrackerEvent:CSStreamSensePause
                               mediaPlayer:segmentsController.playerController
                                   segment:previousSegment];
            [self notifyStreamTrackerEvent:CSStreamSensePlay
                               mediaPlayer:segmentsController.playerController
                                   segment:nil];
            break;
        }
            
        default:
            break;
    }
}


- (void)mediaPlayerPlaybackDidFail:(NSNotification *)notification
{
	RTSMediaPlayerController *mediaPlayerController = notification.object;
	if ([self shouldTrackMediaPlayerController:mediaPlayerController])
		[self stopTrackingMediaPlayerController:mediaPlayerController];
}



#pragma mark - Stream tracking

- (void)trackMediaPlayerFromPresentingViewController:(id<RTSAnalyticsMediaPlayerDelegate>)mediaPlayerDelegate
{
	_mediaPlayerDelegate = mediaPlayerDelegate;
}

- (void)startTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	[self notifyStreamTrackerEvent:CSStreamSensePlay
                       mediaPlayer:mediaPlayerController
                           segment:nil];
}

- (void)stopTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	if (![self.streamsenseTrackers.allKeys containsObject:mediaPlayerController.identifier])
		return;
	
	[self notifyStreamTrackerEvent:CSStreamSenseEnd
                       mediaPlayer:mediaPlayerController
                           segment:nil];
    
	[CSComScore onUxInactive];
    
	RTSAnalyticsLogVerbose(@"Delete stream tracker for media identifier `%@`", mediaPlayerController.identifier);
	[self.streamsenseTrackers removeObjectForKey:mediaPlayerController.identifier];	
}

- (void)notifyStreamTrackerEvent:(CSStreamSenseEventType)eventType
                     mediaPlayer:(RTSMediaPlayerController *)mediaPlayerController
                         segment:(id<RTSMediaSegment>)segment
{
	RTSMediaPlayerControllerStreamSenseTracker *tracker = self.streamsenseTrackers[mediaPlayerController.identifier];
	if (!tracker) {
		RTSAnalyticsLogVerbose(@"Create a new stream tracker for media identifier `%@`", mediaPlayerController.identifier);
		
		tracker = [[RTSMediaPlayerControllerStreamSenseTracker alloc] initWithPlayer:mediaPlayerController
                                                                          dataSource:self.dataSource
                                                                         virtualSite:self.virtualSite];
        
		self.streamsenseTrackers[mediaPlayerController.identifier] = tracker;
		[CSComScore onUxActive];
	}
	
    RTSAnalyticsLogVerbose(@"Notify stream tracker event %@ for media identifier `%@`", @(eventType), mediaPlayerController.identifier);
    [tracker notify:eventType withSegment:segment];
}

@end
