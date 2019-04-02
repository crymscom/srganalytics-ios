//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGComScoreMediaPlayerTracker.h"

#import "SRGAnalyticsMediaPlayerLogger.h"
#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

#import <ComScore/ComScore.h>
#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

static NSMutableDictionary<NSValue *, SRGComScoreMediaPlayerTracker *> *s_trackers = nil;

@interface SRGComScoreMediaPlayerTracker ()

@property (nonatomic, weak) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation SRGComScoreMediaPlayerTracker

#pragma mark Object lifecycle

- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (self = [super init]) {
        self.mediaPlayerController = mediaPlayerController;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackStateDidChange:)
                                                   name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                 object:mediaPlayerController];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(segmentDidStart:)
                                                   name:SRGMediaPlayerSegmentDidStartNotification
                                                 object:mediaPlayerController];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(segmentDidEnd:)
                                                   name:SRGMediaPlayerSegmentDidEndNotification
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

- (void)segmentDidStart:(NSNotification *)notification
{
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    if (! mediaPlayerController.tracked) {
        return;
    }
    
    // TODO:
}

- (void)segmentDidEnd:(NSNotification *)notification
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
