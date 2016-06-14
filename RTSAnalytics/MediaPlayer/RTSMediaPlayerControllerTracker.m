//
//  Copyright (c) SRG SSR. All rights reserved.
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
#import <SRGMediaPlayer/RTSMediaSegment.h>
#import "RTSMediaPlayerControllerStreamSenseTracker_private.h"

#import <ComScore/CSComScore.h>

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
    if (!mediaPlayerController.identifier) {
        return;
    }
    
    RTSMediaPlayerControllerTrackingInfo *trackingInfo = [self trackingInfoForMediaPlayerController:mediaPlayerController];
    
    RTSAnalyticsLogDebug(@"---> Playback status changed: %@", @(mediaPlayerController.playbackState));
    
	if (mediaPlayerController.tracked) {
		switch (mediaPlayerController.playbackState) {
			case RTSMediaPlaybackStatePreparing:
				[self notifyStreamTrackerEvent:CSStreamSenseBuffer
                                   mediaPlayer:mediaPlayerController
                                       segment:trackingInfo.currentSegment];
				break;
				
			case RTSMediaPlaybackStateReady:
                [self notifyComScoreOfReadyToPlayEvent:mediaPlayerController];
				break;
				
			case RTSMediaPlaybackStateStalled:
				[self notifyStreamTrackerEvent:CSStreamSenseBuffer
                                   mediaPlayer:mediaPlayerController
                                       segment:trackingInfo.currentSegment];
				break;
				
			case RTSMediaPlaybackStatePlaying:
                if (! trackingInfo.currentSegment || ! trackingInfo.skippingNextEvents) {
                    [self notifyStreamTrackerEvent:CSStreamSensePlay
                                       mediaPlayer:mediaPlayerController
                                           segment:trackingInfo.currentSegment];
                }
                
                // Reset event inhibition flags when playback resumes
                trackingInfo.skippingNextEvents = NO;
                trackingInfo.userSelected = NO;
				break;
                
            case RTSMediaPlaybackStateSeeking:
                // Skip seeks because of the user actively selecting a segment 
                if (! trackingInfo.userSelected) {
                    [self notifyStreamTrackerEvent:CSStreamSensePause
                                       mediaPlayer:mediaPlayerController
                                           segment:trackingInfo.currentSegment];
                }
                break;
                
			case RTSMediaPlaybackStatePaused:
                if (! trackingInfo.skippingNextEvents) {
                    [self notifyStreamTrackerEvent:CSStreamSensePause
                                       mediaPlayer:mediaPlayerController
                                           segment:trackingInfo.currentSegment];
                }
				break;
				
			case RTSMediaPlaybackStateEnded:
				[self notifyStreamTrackerEvent:CSStreamSenseEnd
                                   mediaPlayer:mediaPlayerController
                                       segment:trackingInfo.currentSegment];
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
    if (!mediaPlayerController.tracked || !mediaPlayerController.identifier) {
        return;
    }
    
    RTSMediaPlayerControllerTrackingInfo *trackingInfo = [self trackingInfoForMediaPlayerController:mediaPlayerController];
    if (!trackingInfo) {
        return;
    }
    
    NSInteger value = [notification.userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] integerValue];
    BOOL wasUserSelected = [notification.userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue];
    
    id<RTSMediaSegment> previousSegment = trackingInfo.currentSegment;
    id<RTSMediaSegment> segment = notification.userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey];
    trackingInfo.currentSegment = (wasUserSelected ? segment : nil);
    trackingInfo.userSelected = wasUserSelected;
    
    RTSAnalyticsLogDebug(@"---> Segment changed: %@ (prev = %@, next = %@, selected = %@)", @(value), previousSegment, segment, wasUserSelected ? @"YES" : @"NO");
    
    // According to its implementation, Comscore only sends an event if different from the previously sent one. We
    // are therefore required to send an end followed by a play when a segment end is detected (in which case
    // playback continues with another segment or with the full-length). Segment information is sent only if the
    // segment was selected by the user
    switch (value) {
        case RTSMediaPlaybackSegmentStart: {
            if (wasUserSelected) {
                [self notifyStreamTrackerEvent:CSStreamSenseEnd
                                   mediaPlayer:segmentsController.playerController
                                       segment:previousSegment];
                [self notifyStreamTrackerEvent:CSStreamSensePlay
                                   mediaPlayer:segmentsController.playerController
                                       segment:segment];
                
                trackingInfo.skippingNextEvents = YES;
            }
            break;
        }
            
        case RTSMediaPlaybackSegmentSwitch: {
            if (wasUserSelected || previousSegment) {
                [self notifyStreamTrackerEvent:CSStreamSenseEnd
                                   mediaPlayer:segmentsController.playerController
                                       segment:previousSegment];
                [self notifyStreamTrackerEvent:CSStreamSensePlay
                                   mediaPlayer:segmentsController.playerController
                                       segment:(wasUserSelected ? segment : nil)];
            }
            break;
        }
            
        case RTSMediaPlaybackSegmentEnd: {
            if (previousSegment) {
                [self notifyStreamTrackerEvent:CSStreamSenseEnd
                                   mediaPlayer:segmentsController.playerController
                                       segment:previousSegment];
                [self notifyStreamTrackerEvent:CSStreamSensePlay
                                   mediaPlayer:segmentsController.playerController
                                       segment:nil];
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
    NSParameterAssert(mediaPlayerController.identifier);
    
    RTSMediaPlayerControllerTrackingInfo *trackingInfo = self.trackingInfos[mediaPlayerController.identifier];
    if (!trackingInfo) {
        trackingInfo = [[RTSMediaPlayerControllerTrackingInfo alloc] initWithMediaPlayerController:mediaPlayerController];
        self.trackingInfos[mediaPlayerController.identifier] = trackingInfo;
    }
    return trackingInfo;
}

- (void)discardTrackingInfoForMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
    [self.trackingInfos removeObjectForKey:mediaPlayerController.identifier];
}

+ (id<RTSMediaSegment>)fullLengthSegmentForMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id<RTSMediaSegment>  _Nonnull segment, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [mediaPlayerController.identifier isEqualToString:segment.segmentIdentifier] && !segment.logical;
    }];
    return [mediaPlayerController.segmentsController.segments filteredArrayUsingPredicate:predicate].firstObject;
}

#pragma mark - Stream tracking

- (void)startTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	[self notifyStreamTrackerEvent:CSStreamSensePlay
                       mediaPlayer:mediaPlayerController
                           segment:nil];
}

- (void)stopTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
    if (![self.streamsenseTrackers.allKeys containsObject:mediaPlayerController.identifier]) {
		return;
    }
	
    RTSMediaPlayerControllerTrackingInfo *trackingInfo = self.trackingInfos[mediaPlayerController.identifier];
	[self notifyStreamTrackerEvent:CSStreamSenseEnd
                       mediaPlayer:mediaPlayerController
                           segment:trackingInfo.currentSegment];
    [self discardTrackingInfoForMediaPlayerController:mediaPlayerController];
    
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

    // If no segment has been provided, send full-length information
    if (!segment) {
        segment = [RTSMediaPlayerControllerTracker fullLengthSegmentForMediaPlayerController:mediaPlayerController];
    }
    [tracker notify:eventType withSegment:segment];
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
        
        id<RTSMediaSegment> segment = trackingInfo.currentSegment ?: [RTSMediaPlayerControllerTracker fullLengthSegmentForMediaPlayerController:trackingInfo.mediaPlayerController];
        RTSMediaPlayerControllerStreamSenseTracker *tracker = self.streamsenseTrackers[key];
        [tracker updateLabelsWithSegment:segment];
    }
}

@end
