//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSAnalyticsTracker.h"
#import "RTSMediaPlayerControllerTracker_private.h"
#import "RTSAnalyticsLogger.h"
#import "RTSAnalyticsMediaPlayerDataSource.h"
#import "RTSMediaPlayerControllerTrackingInfo.h"
#import "RTSMediaPlayerController+RTSAnalytics.h"

#import <SRGMediaPlayer/RTSMediaPlayerController.h>
#import <SRGMediaPlayer/RTSMediaSegmentsController.h>
#import "RTSMediaPlayerControllerStreamSenseTracker_private.h"

#import <comScore-iOS-SDK-RTS/CSComScore.h>

@interface RTSMediaPlayerControllerTracker ()

@property (nonatomic, weak) id<RTSAnalyticsMediaPlayerDataSource> dataSource;

@property (nonatomic, strong) NSMutableDictionary *trackingInfos;

@property (nonatomic, strong) NSMutableDictionary *streamsenseTrackers;
@property (nonatomic, strong) NSString *virtualSite;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation RTSMediaPlayerControllerTracker

+ (instancetype) sharedTracker
{
	static RTSMediaPlayerControllerTracker *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[[self class] alloc] init_custom_RTSMediaPlayerControllerTracker];
	});
	return sharedInstance;
}

- (id)init_custom_RTSMediaPlayerControllerTracker
{
	if (!(self = [super init]))
		return nil;
	
	_streamsenseTrackers = [NSMutableDictionary new];
    _trackingInfos = [NSMutableDictionary new];
    
    // Periodically update labels so that heartbeats get correct timestamps during playback
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1. target:self selector:@selector(updateLabels:) userInfo:nil repeats:YES];
	
	return self;
}

- (void)dealloc
{
    self.timer = nil;
    
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setTimer:(NSTimer *)timer
{
    if (_timer) {
        [_timer invalidate];
    }
    
    _timer = timer;
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

#pragma mark - Notifications

- (void)mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	if (!_dataSource) {
		// We haven't started yet.
		return;
	}
	
	RTSMediaPlayerController *mediaPlayerController = notification.object;
    RTSMediaPlayerControllerTrackingInfo *trackingInfo = [self trackingInfoForMediaPlayerController:mediaPlayerController];
    
    RTSAnalyticsLogDebug(@"---> Playback status changed: %@", @(mediaPlayerController.playbackState));
    
	if (mediaPlayerController.tracked) {
		switch (mediaPlayerController.playbackState) {
			case RTSMediaPlaybackStatePreparing:
				[self notifyStreamTrackerEvent:CSStreamSenseBuffer
                                   mediaPlayer:mediaPlayerController
                                  trackingInfo:trackingInfo];
				break;
				
			case RTSMediaPlaybackStateReady:
                [self notifyComScoreOfReadyToPlayEvent:mediaPlayerController];
				break;
				
			case RTSMediaPlaybackStateStalled:
				[self notifyStreamTrackerEvent:CSStreamSenseBuffer
                                   mediaPlayer:mediaPlayerController
                                  trackingInfo:trackingInfo];
				break;
				
			case RTSMediaPlaybackStatePlaying:
                if (!trackingInfo.segment || !trackingInfo.skippingNextEvents) {
                    [self notifyStreamTrackerEvent:CSStreamSensePlay
                                       mediaPlayer:mediaPlayerController
                                      trackingInfo:trackingInfo];
                }
                trackingInfo.skippingNextEvents = NO;
				break;
                
            case RTSMediaPlaybackStateSeeking:
                if (!trackingInfo.segment) {
                    [self notifyStreamTrackerEvent:CSStreamSensePause
                                       mediaPlayer:mediaPlayerController
                                      trackingInfo:trackingInfo];
                }
                break;
                
			case RTSMediaPlaybackStatePaused:
                if (!trackingInfo.skippingNextEvents) {
                    [self notifyStreamTrackerEvent:CSStreamSensePause
                                       mediaPlayer:mediaPlayerController
                                      trackingInfo:trackingInfo];
                }
				break;
				
			case RTSMediaPlaybackStateEnded:
				[self notifyStreamTrackerEvent:CSStreamSenseEnd
                                   mediaPlayer:mediaPlayerController
                                  trackingInfo:trackingInfo];
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
    RTSMediaPlayerController *mediaPlayerController = segmentsController.playerController;
    if (!mediaPlayerController.tracked) {
        return;
    }
    
    RTSMediaPlayerControllerTrackingInfo *trackingInfo = [self trackingInfoForMediaPlayerController:mediaPlayerController];
    if (!trackingInfo) {
        return;
    }
    
    // Backup previous values first
    RTSMediaPlayerControllerTrackingInfo *previousTrackingInfo = [trackingInfo copy];
    
    // Update tracking information
    NSInteger value = [notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue];
    BOOL wasUserSelected = [notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue];
    
    id<RTSMediaSegment> segment = wasUserSelected ? notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] : nil;
    if (segment) {
        NSUInteger segmentIndex = [segmentsController indexForSegment:segment];
        
        trackingInfo.segment = segment;
        trackingInfo.customLabels = @{ @"ns_st_pn" : (segmentIndex != NSNotFound) ? @(segmentIndex + 1).stringValue : @"1",
                                       @"ns_st_tp" : @"1" };        // TODO
    }
    else {
        trackingInfo.segment = nil;
        trackingInfo.customLabels = @{ @"ns_st_pn" : @"1",
                                       @"ns_st_tp" : @"1" };        // TODO
    }
    
    RTSAnalyticsLogDebug(@"---> Segment changed: %@ (prev = %@, next = %@, selected = %@)", @(value), previousTrackingInfo.segment,
                         trackingInfo.segment, wasUserSelected ? @"YES" : @"NO");
    
    // According to its implementation, Comscore only sends an event if different from the previously sent one. We
    // are therefore required to send an end followed by a play when a segment end is detected (in which case
    // playback continues with another segment or with the full-length). Segment information is sent only if the
    // segment was selected by the user
    switch (value) {
        case RTSMediaPlaybackSegmentStart: {
            if (wasUserSelected) {
                [self notifyStreamTrackerEvent:CSStreamSenseEnd
                                   mediaPlayer:segmentsController.playerController
                                  trackingInfo:previousTrackingInfo];
                [self notifyStreamTrackerEvent:CSStreamSensePlay
                                   mediaPlayer:segmentsController.playerController
                                  trackingInfo:trackingInfo];
                
                trackingInfo.skippingNextEvents = YES;
            }
            break;
        }
            
        case RTSMediaPlaybackSegmentSwitch: {
            if (wasUserSelected || previousTrackingInfo.segment) {
                [self notifyStreamTrackerEvent:CSStreamSenseEnd
                                   mediaPlayer:segmentsController.playerController
                                  trackingInfo:previousTrackingInfo];
                [self notifyStreamTrackerEvent:CSStreamSensePlay
                                   mediaPlayer:segmentsController.playerController
                                  trackingInfo:trackingInfo];
            }
            break;
        }
            
        case RTSMediaPlaybackSegmentEnd: {
            if (previousTrackingInfo.segment) {
                [self notifyStreamTrackerEvent:CSStreamSenseEnd
                                   mediaPlayer:segmentsController.playerController
                                  trackingInfo:previousTrackingInfo];
                [self notifyStreamTrackerEvent:CSStreamSensePlay
                                   mediaPlayer:segmentsController.playerController
                                  trackingInfo:trackingInfo];
            }
            break;
        }
            
        default:
            break;
    }
}


- (void)mediaPlayerPlaybackDidFail:(NSNotification *)notification
{
	RTSMediaPlayerController *mediaPlayerController = notification.object;
    if (mediaPlayerController.tracked) {
		[self stopTrackingMediaPlayerController:mediaPlayerController];
    }
}

#pragma mark - Tracking information

- (RTSMediaPlayerControllerTrackingInfo *)trackingInfoForMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
    if (!mediaPlayerController) {
        return nil;
    }
    
    RTSMediaPlayerControllerTrackingInfo *trackingInfo = self.trackingInfos[mediaPlayerController.identifier];
    if (!trackingInfo) {
        trackingInfo = [RTSMediaPlayerControllerTrackingInfo new];
        self.trackingInfos[mediaPlayerController.identifier] = trackingInfo;
    }
    return trackingInfo;
}

- (void)discardTrackingInfoForMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
    [self.trackingInfos removeObjectForKey:mediaPlayerController.identifier];
}


#pragma mark - Stream tracking

- (void)startTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
    // TODO: Tracking info?
	[self notifyStreamTrackerEvent:CSStreamSensePlay
                       mediaPlayer:mediaPlayerController
                      trackingInfo:nil];
}

- (void)stopTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
    if (![self.streamsenseTrackers.allKeys containsObject:mediaPlayerController.identifier]) {
		return;
    }
	
    // TODO: Tracking info?
    [self discardTrackingInfoForMediaPlayerController:mediaPlayerController];
	[self notifyStreamTrackerEvent:CSStreamSenseEnd
                       mediaPlayer:mediaPlayerController
                      trackingInfo:nil];
    
	[CSComScore onUxInactive];
    
	RTSAnalyticsLogVerbose(@"Delete stream tracker for media identifier `%@`", mediaPlayerController.identifier);
	[self.streamsenseTrackers removeObjectForKey:mediaPlayerController.identifier];	
}

- (void)notifyStreamTrackerEvent:(CSStreamSenseEventType)eventType
                     mediaPlayer:(RTSMediaPlayerController *)mediaPlayerController
                    trackingInfo:(RTSMediaPlayerControllerTrackingInfo *)trackingInfo
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
    [tracker notify:eventType withSegment:trackingInfo.segment customLabels:trackingInfo.customLabels];
}

- (void)notifyComScoreOfReadyToPlayEvent:(RTSMediaPlayerController *)mediaPlayerController
{
    if ([self.dataSource respondsToSelector:@selector(comScoreReadyToPlayLabelsForIdentifier:)]) {
        NSDictionary *labels = [self.dataSource comScoreReadyToPlayLabelsForIdentifier:mediaPlayerController.identifier];
        if (labels) {
            RTSAnalyticsLogVerbose(@"Notify comScore view event for media identifier `%@`", mediaPlayerController.identifier);
            [CSComScore viewWithLabels:labels];
        }
    }
}

#pragma mark - Timer

- (void)updateLabels:(NSTimer *)timer
{
    for (NSValue *key in [self.streamsenseTrackers allKeys]) {
        RTSMediaPlayerControllerTrackingInfo *trackingInfo = self.trackingInfos[key];
        if (!trackingInfo) {
            continue;
        }
        
        RTSMediaPlayerControllerStreamSenseTracker *tracker = self.streamsenseTrackers[key];
        [tracker updateLabelsWithSegment:trackingInfo.segment customLabels:trackingInfo.customLabels];
    }
}

@end
