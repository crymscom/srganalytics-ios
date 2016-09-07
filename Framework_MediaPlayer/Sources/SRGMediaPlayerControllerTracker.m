//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerControllerTracker.h"
#import "SRGAnalyticsMediaPlayerDataSource.h"
#import "SRGMediaPlayerControllerTrackingInfo.h"
#import "SRGMediaPlayerController+SRGAnalytics.h"
#import "SRGMediaPlayerControllerStreamSenseTracker.h"

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <ComScore/CSComScore.h>

@interface SRGMediaPlayerControllerTracker ()

@property (nonatomic, weak) id<SRGAnalyticsMediaPlayerDataSource> dataSource;

@property (nonatomic, strong) NSMutableDictionary *trackingInfos;

@property (nonatomic, strong) NSMutableDictionary *streamsenseTrackers;
@property (nonatomic, strong) NSString *virtualSite;

@end

@implementation SRGMediaPlayerControllerTracker

+ (instancetype) sharedTracker
{
	static SRGMediaPlayerControllerTracker *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[[self class] alloc] init_custom_SRGMediaPlayerControllerTracker];
	});
	return sharedInstance;
}

- (id)init_custom_SRGMediaPlayerControllerTracker
{
	if (!(self = [super init]))
		return nil;
	
	_streamsenseTrackers = [NSMutableDictionary new];
    _trackingInfos = [NSMutableDictionary new];
    
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startStreamMeasurementForVirtualSite:(NSString *)virtualSite mediaDataSource:(id<SRGAnalyticsMediaPlayerDataSource>)dataSource
{
    NSParameterAssert(virtualSite && dataSource);
    
    if (!_dataSource && !_virtualSite) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mediaPlayerPlaybackStateDidChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:nil];
// TODO: Old SRGMediaPlaybackSegmentDidChangeNotification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mediaPlayerPlaybackSegmentsDidChange:)
                                                     name:SRGMediaPlayerSegmentDidStartNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mediaPlayerPlaybackSegmentsDidChange:)
                                                     name:SRGMediaPlayerSegmentDidEndNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mediaPlayerPlaybackDidFail:)
                                                     name:SRGMediaPlayerPlaybackDidFailNotification
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
	
	SRGMediaPlayerController *mediaPlayerController = notification.object;
    NSString *identifier = mediaPlayerController.userInfo[SRGAnalyticsIdentifierInfoKey] ?: notification.userInfo[SRGMediaPlayerPreviousUserInfoKey][SRGAnalyticsIdentifierInfoKey];
    if (!identifier) {
        return;
    }
    
    SRGMediaPlayerControllerTrackingInfo *trackingInfo = [self trackingInfoForMediaPlayerController:mediaPlayerController forIdentifier:identifier];
    
    SRGAnalyticsLogDebug(@"---> Playback status changed: %@", @(mediaPlayerController.playbackState));
    
	if (mediaPlayerController.tracked) {
		switch (mediaPlayerController.playbackState) {
			case SRGMediaPlayerPlaybackStatePreparing:
				[self notifyStreamTrackerEvent:CSStreamSenseBuffer
                                   mediaPlayer:mediaPlayerController
                                       segment:trackingInfo.currentSegment
                                 forIdentifier:identifier];
				break;
                
			case SRGMediaPlayerPlaybackStateStalled:
				[self notifyStreamTrackerEvent:CSStreamSenseBuffer
                                   mediaPlayer:mediaPlayerController
                                       segment:trackingInfo.currentSegment
                                 forIdentifier:identifier];
				break;
				
			case SRGMediaPlayerPlaybackStatePlaying:
                if ([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing) {
                    [self notifyComScoreOfReadyToPlayEventForIdentifier:identifier];
                }
                
                if (! trackingInfo.currentSegment || ! trackingInfo.skippingNextEvents) {
                    [self notifyStreamTrackerEvent:CSStreamSensePlay
                                       mediaPlayer:mediaPlayerController
                                           segment:trackingInfo.currentSegment
                                     forIdentifier:identifier];
                }
                
                // Reset event inhibition flags when playback resumes
                trackingInfo.skippingNextEvents = NO;
                trackingInfo.userSelected = NO;
				break;
                
            case SRGMediaPlayerPlaybackStateSeeking:
                // Skip seeks because of the user actively selecting a segment 
                if (! trackingInfo.userSelected) {
                    [self notifyStreamTrackerEvent:CSStreamSensePause
                                       mediaPlayer:mediaPlayerController
                                           segment:trackingInfo.currentSegment
                                     forIdentifier:identifier];
                }
                break;
                
			case SRGMediaPlayerPlaybackStatePaused:
                if ([notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing) {
                    [self notifyComScoreOfReadyToPlayEventForIdentifier:identifier];
                }
                
                if (! trackingInfo.skippingNextEvents) {
                    [self notifyStreamTrackerEvent:CSStreamSensePause
                                       mediaPlayer:mediaPlayerController
                                           segment:trackingInfo.currentSegment
                                     forIdentifier:identifier];
                }
				break;
				
			case SRGMediaPlayerPlaybackStateEnded:
				[self notifyStreamTrackerEvent:CSStreamSenseEnd
                                   mediaPlayer:mediaPlayerController
                                       segment:trackingInfo.currentSegment
                                 forIdentifier:identifier];
				break;
				
			case SRGMediaPlayerPlaybackStateIdle:
				[self stopTrackingMediaPlayerControllerForIdentifier:identifier];
				break;
		}
	}
	else if (self.streamsenseTrackers[identifier]) {
		[self stopTrackingMediaPlayerControllerForIdentifier:identifier];
	}
}

- (void)mediaPlayerPlaybackSegmentsDidChange:(NSNotification *)notification
{
    NSLog(@"%@", notification);
    
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    
    NSString *identifier = mediaPlayerController.userInfo[SRGAnalyticsIdentifierInfoKey];
    if (!mediaPlayerController.tracked || !identifier) {
        return;
    }

    SRGMediaPlayerControllerTrackingInfo *trackingInfo = [self trackingInfoForMediaPlayerController:mediaPlayerController forIdentifier:identifier];
    if (!trackingInfo) {
        return;
    }

    BOOL wasUserSelected = [notification.userInfo[SRGMediaPlayerSelectedKey] boolValue];
    
    id<SRGSegment> previousSegment = trackingInfo.currentSegment;
    id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
    trackingInfo.currentSegment = (wasUserSelected ? segment : nil);
    trackingInfo.userSelected = wasUserSelected;
    
    SRGAnalyticsLogDebug(@"---> Segment changed: %@ (prev = %@, next = %@, selected = %@)", notification.name, previousSegment, segment, wasUserSelected ? @"YES" : @"NO");
    
    // According to its implementation, Comscore only sends an event if different from the previously sent one. We
    // are therefore required to send an end followed by a play when a segment end is detected (in which case
    // playback continues with another segment or with the full-length). Segment information is sent only if the
    // segment was selected by the user
    
    if ([notification.name isEqualToString:SRGMediaPlayerSegmentDidStartNotification])
    {
        if (wasUserSelected) {
            [self notifyStreamTrackerEvent:CSStreamSenseEnd
                               mediaPlayer:mediaPlayerController
                                   segment:previousSegment
                             forIdentifier:identifier];
            [self notifyStreamTrackerEvent:CSStreamSensePlay
                               mediaPlayer:mediaPlayerController
                                   segment:segment
                             forIdentifier:identifier];
            
            trackingInfo.skippingNextEvents = YES;
        }
    }
    else if ([notification.name isEqualToString:SRGMediaPlayerSegmentDidEndNotification])
    {
        if (previousSegment) {
            [self notifyStreamTrackerEvent:CSStreamSenseEnd
                               mediaPlayer:mediaPlayerController
                                   segment:previousSegment
                             forIdentifier:identifier];
            [self notifyStreamTrackerEvent:CSStreamSensePlay
                               mediaPlayer:mediaPlayerController
                                   segment:nil
                             forIdentifier:identifier];
        }
    }
}


- (void)mediaPlayerPlaybackDidFail:(NSNotification *)notification
{
	SRGMediaPlayerController *mediaPlayerController = notification.object;
    if (mediaPlayerController.tracked) {
		[self stopTrackingMediaPlayerControllerForIdentifier:mediaPlayerController.userInfo[SRGAnalyticsIdentifierInfoKey]];
    }
}

#pragma mark - Tracking information

- (SRGMediaPlayerControllerTrackingInfo *)trackingInfoForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController forIdentifier:(NSString *)identifier
{
    NSParameterAssert(identifier);
    
    SRGMediaPlayerControllerTrackingInfo *trackingInfo = self.trackingInfos[identifier];
    if (!trackingInfo) {
        trackingInfo = [[SRGMediaPlayerControllerTrackingInfo alloc] initWithMediaPlayerController:mediaPlayerController];
        self.trackingInfos[identifier] = trackingInfo;
    }
    return trackingInfo;
}

- (void)discardTrackingInfoForIdentifier:(NSString *)identifier
{
    [self.trackingInfos removeObjectForKey:identifier];
}

+ (id<SRGSegment>)fullLengthSegmentForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
// TODO: fullLengthSegmentForMediaPlayerController
//    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id<SRGSegment>  _Nonnull segment, NSDictionary<NSString *,id> * _Nullable bindings) {
//        return [self.dataSource.identifier isEqualToString:segment.segmentIdentifier];
//    }];
//    return [mediaPlayerController.segmentsController.segments filteredArrayUsingPredicate:predicate].firstObject;
    return nil;
}

#pragma mark - Stream tracking

- (void)startTrackingMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController forIdentifier:(NSString *)identifier
{
	[self notifyStreamTrackerEvent:CSStreamSensePlay
                       mediaPlayer:mediaPlayerController
                           segment:nil
                     forIdentifier:identifier];
}

- (void)stopTrackingMediaPlayerControllerForIdentifier:(NSString *)identifier
{
    if (![self.streamsenseTrackers.allKeys containsObject:identifier]) {
		return;
    }
	
    SRGMediaPlayerControllerTrackingInfo *trackingInfo = self.trackingInfos[identifier];
	[self notifyStreamTrackerEvent:CSStreamSenseEnd
                       mediaPlayer:trackingInfo.mediaPlayerController
                           segment:trackingInfo.currentSegment
                     forIdentifier:identifier];
    [self discardTrackingInfoForIdentifier:identifier];
    
	[CSComScore onUxInactive];
    
	SRGAnalyticsLogVerbose(@"Delete stream tracker for media identifier `%@`", identifier);
	[self.streamsenseTrackers removeObjectForKey:identifier];
}

- (void)notifyStreamTrackerEvent:(CSStreamSenseEventType)eventType
                     mediaPlayer:(SRGMediaPlayerController *)mediaPlayerController
                         segment:(id<SRGSegment>)segment
                   forIdentifier:(NSString *)identifier
{
	SRGMediaPlayerControllerStreamSenseTracker *tracker = self.streamsenseTrackers[identifier];
	if (!tracker) {
		SRGAnalyticsLogVerbose(@"Create a new stream tracker for media identifier `%@`", identifier);
		
		tracker = [[SRGMediaPlayerControllerStreamSenseTracker alloc] initWithPlayer:mediaPlayerController
                                                                          dataSource:self.dataSource
                                                                         virtualSite:self.virtualSite];
        
		self.streamsenseTrackers[identifier] = tracker;
		[CSComScore onUxActive];
	}
	
    SRGAnalyticsLogVerbose(@"Notify stream tracker event %@ for media identifier `%@`", @(eventType), identifier);

    // If no segment has been provided, send full-length information
    if (!segment) {
        segment = [SRGMediaPlayerControllerTracker fullLengthSegmentForMediaPlayerController:mediaPlayerController];
    }
    [tracker notify:eventType withSegment:segment forIdentifier:identifier];
}

- (void)notifyComScoreOfReadyToPlayEventForIdentifier:(NSString *)identifier
{
    if ([self.dataSource respondsToSelector:@selector(comScoreReadyToPlayLabelsForIdentifier:)]) {
        NSDictionary *labels = [self.dataSource comScoreReadyToPlayLabelsForIdentifier:identifier];
        if (labels) {
            SRGAnalyticsLogVerbose(@"Notify comScore view event for media identifier `%@`", identifier);
            [CSComScore viewWithLabels:labels];
        }
    }
}

@end
