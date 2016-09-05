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
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(mediaPlayerPlaybackSegmentsDidChange:)
//                                                     name:SRGMediaPlaybackSegmentDidChangeNotification
//                                                   object:nil];

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
    if (!mediaPlayerController.identifier) {
        return;
    }
    
    SRGMediaPlayerControllerTrackingInfo *trackingInfo = [self trackingInfoForMediaPlayerController:mediaPlayerController];
    
    SRGAnalyticsLogDebug(@"---> Playback status changed: %@", @(mediaPlayerController.playbackState));
    
	if (mediaPlayerController.tracked) {
		switch (mediaPlayerController.playbackState) {
			case SRGMediaPlayerPlaybackStatePreparing:
				[self notifyStreamTrackerEvent:CSStreamSenseBuffer
                                   mediaPlayer:mediaPlayerController
                                       segment:trackingInfo.currentSegment];
				break;

// TODO: SRGMediaPlaybackStateReady state
//			case SRGMediaPlaybackStateReady:
//                [self notifyComScoreOfReadyToPlayEvent:mediaPlayerController];
//				break;
				
			case SRGMediaPlayerPlaybackStateStalled:
				[self notifyStreamTrackerEvent:CSStreamSenseBuffer
                                   mediaPlayer:mediaPlayerController
                                       segment:trackingInfo.currentSegment];
				break;
				
			case SRGMediaPlayerPlaybackStatePlaying:
                if (! trackingInfo.currentSegment || ! trackingInfo.skippingNextEvents) {
                    [self notifyStreamTrackerEvent:CSStreamSensePlay
                                       mediaPlayer:mediaPlayerController
                                           segment:trackingInfo.currentSegment];
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
                                           segment:trackingInfo.currentSegment];
                }
                break;
                
			case SRGMediaPlayerPlaybackStatePaused:
                if (! trackingInfo.skippingNextEvents) {
                    [self notifyStreamTrackerEvent:CSStreamSensePause
                                       mediaPlayer:mediaPlayerController
                                           segment:trackingInfo.currentSegment];
                }
				break;
				
			case SRGMediaPlayerPlaybackStateEnded:
				[self notifyStreamTrackerEvent:CSStreamSenseEnd
                                   mediaPlayer:mediaPlayerController
                                       segment:trackingInfo.currentSegment];
				break;
				
			case SRGMediaPlayerPlaybackStateIdle:
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
// TODO: mediaPlayerPlaybackSegmentsDidChange notification
//    SRGMediaSegmentsController *segmentsController = notification.object;
//    SRGMediaPlayerController *mediaPlayerController = segmentsController.playerController;
//    if (!mediaPlayerController.tracked || !mediaPlayerController.identifier) {
//        return;
//    }
//    
//    SRGMediaPlayerControllerTrackingInfo *trackingInfo = [self trackingInfoForMediaPlayerController:mediaPlayerController];
//    if (!trackingInfo) {
//        return;
//    }
//    
//    NSInteger value = [notification.userInfo[SRGMediaPlaybackSegmentChangeValueInfoKey] integerValue];
//    BOOL wasUserSelected = [notification.userInfo[SRGMediaPlaybackSegmentChangeUserSelectInfoKey] boolValue];
//    
//    id<SRGSegment> previousSegment = trackingInfo.currentSegment;
//    id<SRGSegment> segment = notification.userInfo[SRGMediaPlaybackSegmentChangeSegmentInfoKey];
//    trackingInfo.currentSegment = (wasUserSelected ? segment : nil);
//    trackingInfo.userSelected = wasUserSelected;
//    
//    SRGAnalyticsLogDebug(@"---> Segment changed: %@ (prev = %@, next = %@, selected = %@)", @(value), previousSegment, segment, wasUserSelected ? @"YES" : @"NO");
//    
//    // According to its implementation, Comscore only sends an event if different from the previously sent one. We
//    // are therefore required to send an end followed by a play when a segment end is detected (in which case
//    // playback continues with another segment or with the full-length). Segment information is sent only if the
//    // segment was selected by the user
//    switch (value) {
//        case SRGMediaPlaybackSegmentStart: {
//            if (wasUserSelected) {
//                [self notifyStreamTrackerEvent:CSStreamSenseEnd
//                                   mediaPlayer:segmentsController.playerController
//                                       segment:previousSegment];
//                [self notifyStreamTrackerEvent:CSStreamSensePlay
//                                   mediaPlayer:segmentsController.playerController
//                                       segment:segment];
//                
//                trackingInfo.skippingNextEvents = YES;
//            }
//            break;
//        }
//            
//        case SRGMediaPlaybackSegmentSwitch: {
//            if (wasUserSelected || previousSegment) {
//                [self notifyStreamTrackerEvent:CSStreamSenseEnd
//                                   mediaPlayer:segmentsController.playerController
//                                       segment:previousSegment];
//                [self notifyStreamTrackerEvent:CSStreamSensePlay
//                                   mediaPlayer:segmentsController.playerController
//                                       segment:(wasUserSelected ? segment : nil)];
//            }
//            break;
//        }
//            
//        case SRGMediaPlaybackSegmentEnd: {
//            if (previousSegment) {
//                [self notifyStreamTrackerEvent:CSStreamSenseEnd
//                                   mediaPlayer:segmentsController.playerController
//                                       segment:previousSegment];
//                [self notifyStreamTrackerEvent:CSStreamSensePlay
//                                   mediaPlayer:segmentsController.playerController
//                                       segment:nil];
//            }
//            break;
//        }
//            
//        default:
//            break;
//    }
}


- (void)mediaPlayerPlaybackDidFail:(NSNotification *)notification
{
	SRGMediaPlayerController *mediaPlayerController = notification.object;
    if (mediaPlayerController.tracked) {
		[self stopTrackingMediaPlayerController:mediaPlayerController];
    }
}

#pragma mark - Tracking information

- (SRGMediaPlayerControllerTrackingInfo *)trackingInfoForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    NSParameterAssert(mediaPlayerController.identifier);
    
    SRGMediaPlayerControllerTrackingInfo *trackingInfo = self.trackingInfos[mediaPlayerController.identifier];
    if (!trackingInfo) {
        trackingInfo = [[SRGMediaPlayerControllerTrackingInfo alloc] initWithMediaPlayerController:mediaPlayerController];
        self.trackingInfos[mediaPlayerController.identifier] = trackingInfo;
    }
    return trackingInfo;
}

- (void)discardTrackingInfoForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    [self.trackingInfos removeObjectForKey:mediaPlayerController.identifier];
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

- (void)startTrackingMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
	[self notifyStreamTrackerEvent:CSStreamSensePlay
                       mediaPlayer:mediaPlayerController
                           segment:nil];
}

- (void)stopTrackingMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (![self.streamsenseTrackers.allKeys containsObject:mediaPlayerController.identifier]) {
		return;
    }
	
    SRGMediaPlayerControllerTrackingInfo *trackingInfo = self.trackingInfos[mediaPlayerController.identifier];
	[self notifyStreamTrackerEvent:CSStreamSenseEnd
                       mediaPlayer:mediaPlayerController
                           segment:trackingInfo.currentSegment];
    [self discardTrackingInfoForMediaPlayerController:mediaPlayerController];
    
	[CSComScore onUxInactive];
    
	SRGAnalyticsLogVerbose(@"Delete stream tracker for media identifier `%@`", mediaPlayerController.identifier);
	[self.streamsenseTrackers removeObjectForKey:mediaPlayerController.identifier];
}

- (void)notifyStreamTrackerEvent:(CSStreamSenseEventType)eventType
                     mediaPlayer:(SRGMediaPlayerController *)mediaPlayerController
                         segment:(id<SRGSegment>)segment
{
	SRGMediaPlayerControllerStreamSenseTracker *tracker = self.streamsenseTrackers[mediaPlayerController.identifier];
	if (!tracker) {
		SRGAnalyticsLogVerbose(@"Create a new stream tracker for media identifier `%@`", mediaPlayerController.identifier);
		
		tracker = [[SRGMediaPlayerControllerStreamSenseTracker alloc] initWithPlayer:mediaPlayerController
                                                                          dataSource:self.dataSource
                                                                         virtualSite:self.virtualSite];
        
		self.streamsenseTrackers[mediaPlayerController.identifier] = tracker;
		[CSComScore onUxActive];
	}
	
    SRGAnalyticsLogVerbose(@"Notify stream tracker event %@ for media identifier `%@`", @(eventType), mediaPlayerController.identifier);

    // If no segment has been provided, send full-length information
    if (!segment) {
        segment = [SRGMediaPlayerControllerTracker fullLengthSegmentForMediaPlayerController:mediaPlayerController];
    }
    [tracker notify:eventType withSegment:segment];
}

- (void)notifyComScoreOfReadyToPlayEvent:(SRGMediaPlayerController *)mediaPlayerController
{
    if ([self.dataSource respondsToSelector:@selector(comScoreReadyToPlayLabelsForIdentifier:)]) {
        NSDictionary *labels = [self.dataSource comScoreReadyToPlayLabelsForIdentifier:mediaPlayerController.identifier];
        if (labels) {
            SRGAnalyticsLogVerbose(@"Notify comScore view event for media identifier `%@`", mediaPlayerController.identifier);
            [CSComScore viewWithLabels:labels];
        }
    }
}

@end
