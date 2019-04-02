//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGComScoreMediaPlayerTracker.h"

#import "SRGAnalyticsMediaPlayerLogger.h"
#import "SRGMediaAnalytics.h"
#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

#import <ComScore/ComScore.h>
#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

static NSMutableDictionary<NSValue *, SRGComScoreMediaPlayerTracker *> *s_trackers = nil;

@interface SRGComScoreMediaPlayerTracker ()

@property (nonatomic, weak) SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic) SCORStreamingAnalytics *streamingAnalytics;

@end

@implementation SRGComScoreMediaPlayerTracker

#pragma mark Object lifecycle

- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (self = [super init]) {
        self.mediaPlayerController = mediaPlayerController;
        
        self.streamingAnalytics = [[SCORStreamingAnalytics alloc] init];
        [self.streamingAnalytics createPlaybackSession];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackStateDidChange:)
                                                   name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                 object:mediaPlayerController];
        
        @weakify(self)
        [mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, tracked) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            
            SRGMediaPlayerController *mediaPlayerController = self.mediaPlayerController;
            if (mediaPlayerController.tracked) {
                // TODO:
            }
            else {
                // TODO:
            }
        }];
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithMediaPlayerController:nil];
}

#pragma clang diagnostic pop

#pragma mark Tracking

// TODO: Buffering. Preparing = buffering? Stalled = Buffering? Seeking = Buffering? Or simply deal separately from
//       player state?

// TODO: Restore tracker labels!! (for comScore labels stemming from the IL!)
// TODO: Check that confcall hints have been implemented
// TODO: Create common tracker parent class which deals with registrations and calls hooks (MP registration,
//       notifications, tracked boolean changes)

- (void)recordEventForPlaybackState:(SRGMediaPlayerPlaybackState)playbackState
                       withPosition:(NSTimeInterval)position
{
    // Important: Never alter the stream type afterwards. Once we have determined the stream supports DVR, stick with
    // it (the window length and offset can be updated, though).
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        [self.streamingAnalytics setDVRWindowLength:CMTimeGetSeconds(self.mediaPlayerController.timeRange.duration) * 1000];
        [self.streamingAnalytics setDVRWindowOffset:SRGMediaAnalyticsPlayerTimeshiftInMilliseconds(self.mediaPlayerController).integerValue];
    }
    
    // Labels sent with `-notify` methods are only associated with the event and not persisted for other events (e.g.
    // heartbeats). We therefore *must* use label-less methods only.
    switch (playbackState) {
        case SRGMediaPlayerPlaybackStatePlaying: {
            [self.streamingAnalytics notifyPlayWithPosition:position];
            break;
        }
            
        case SRGMediaPlayerPlaybackStatePaused: {
            [self.streamingAnalytics notifyPauseWithPosition:position];
            break;
        }
            
        case SRGMediaPlayerPlaybackStateEnded: {
            [self.streamingAnalytics notifyEndWithPosition:position];
            break;
        }
            
        case SRGMediaPlayerPlaybackStateSeeking: {
            [self.streamingAnalytics notifySeekStartWithPosition:position];
            break;
        }
            
        default: {
            break;
        }
    }
}

#pragma mark Notifications

+ (void)playbackStateDidChange:(NSNotification *)notification
{
    if (! SRGAnalyticsTracker.sharedTracker.configuration) {
        return;
    }
    
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    NSValue *key = [NSValue valueWithNonretainedObject:mediaPlayerController];
    
    SRGMediaPlayerPlaybackState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
    SRGMediaPlayerPlaybackState previousPlaybackState = [notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue];
    
    // Always attach a tracker to a the player controller, whether or not it is actually tracked (otherwise we would
    // be unable to attach to initially untracked controller later).
    if (playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        SRGComScoreMediaPlayerTracker *tracker = [[SRGComScoreMediaPlayerTracker alloc] initWithMediaPlayerController:mediaPlayerController];
        s_trackers[key] = tracker;
        if (s_trackers.count == 1) {
            [SCORAnalytics notifyUxActive];
        }
        
        SRGAnalyticsMediaPlayerLogInfo(@"comScoreTracker", @"Started tracking for %@", key);
    }
    else if (playbackState == SRGMediaPlayerPlaybackStateIdle) {
        SRGComScoreMediaPlayerTracker *tracker = s_trackers[key];
        if (tracker) {
            if (previousPlaybackState != SRGMediaPlayerPlaybackStatePreparing) {
                
            }
            s_trackers[key] = nil;
            if (s_trackers.count == 0) {
                [SCORAnalytics notifyUxInactive];
            }
            
            SRGAnalyticsMediaPlayerLogInfo(@"comScoreTracker", @"Stopped tracking for %@", key);
        }
    }
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    if (! mediaPlayerController.tracked) {
        return;
    }
    
    // TODO:
}

@end

#pragma mark Static functions

__attribute__((constructor)) static void SRGMediaPlayerTrackerInit(void)
{
    // Observe state changes for all media player controllers to create and remove trackers on the fly
    [NSNotificationCenter.defaultCenter addObserver:SRGComScoreMediaPlayerTracker.class
                                           selector:@selector(playbackStateDidChange:)
                                               name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                             object:nil];
    
    s_trackers = [NSMutableDictionary dictionary];
}
