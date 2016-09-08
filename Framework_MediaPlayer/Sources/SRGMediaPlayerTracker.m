//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerTracker.h"

// FIXME: Due to internal comScore bugs, the object will never be properly released. This does not hurt in our implementaton,
//        but this could be fixed

static NSMutableDictionary *s_trackers = nil;

@interface SRGMediaPlayerTracker ()

@property (nonatomic, weak) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation SRGMediaPlayerTracker

#pragma mark Object lifecycle

- (id)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (self = [super init]) {
        self.mediaPlayerController = mediaPlayerController;
    }
    return self;
}

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithMediaPlayerController:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Tracker management

- (void)start
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateDidChange:)
                                                 name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                               object:self.mediaPlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(segmentDidStart:)
                                                 name:SRGMediaPlayerSegmentDidStartNotification
                                               object:self.mediaPlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(segmentDidEnd:)
                                                 name:SRGMediaPlayerSegmentDidEndNotification
                                               object:self.mediaPlayerController];
    
    [self notify:CSStreamSenseBuffer position:[self currentPositionInMilliseconds] labels:nil];
}

- (void)stop
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                  object:self.mediaPlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SRGMediaPlayerSegmentDidStartNotification
                                                  object:self.mediaPlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SRGMediaPlayerSegmentDidEndNotification
                                                  object:self.mediaPlayerController];
    
    [self notify:CSStreamSenseEnd position:[self currentPositionInMilliseconds] labels:nil];
}

#pragma mark Helpers

- (long)currentPositionInMilliseconds
{
    // Live stream: Playhead position must be always 0
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive
            || self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        return 0;
    }
    else {
        CMTime currentTime = [self.mediaPlayerController.player.currentItem currentTime];
        if (CMTIME_IS_INDEFINITE(currentTime)) {
            return 0;
        }
        else {
            return (long)floor(CMTimeGetSeconds(currentTime) * 1000);
        }
    }
}

#pragma mark Notifications

+ (void)playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    
    NSValue *key = [NSValue valueWithNonretainedObject:mediaPlayerController];
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        NSAssert(s_trackers[key] == nil, @"No tracker must exist");
        SRGMediaPlayerTracker *tracker = [[SRGMediaPlayerTracker alloc] initWithMediaPlayerController:mediaPlayerController];
        
        s_trackers[key] = tracker;
        if (s_trackers.count == 1) {
            [CSComScore onUxActive];
        }
        
        [tracker start];
    }
    else if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        SRGMediaPlayerTracker *tracker = s_trackers[key];
        NSAssert(tracker != nil, @"A tracker must exist");
        [tracker stop];
        
        [s_trackers removeObjectForKey:key];
        if (s_trackers.count == 0) {
            [CSComScore onUxInactive];
        }
    }
}

// TODO: Warning: Test label persistence. Previously, labels were set on the tracker and updated / removed. Could we
//       avoid such issues by always using the -notify labels parameter (building the label dictionary with base labels
//       and custom labels)?

- (void)playbackStateDidChange:(NSNotification *)notification
{
    switch (self.mediaPlayerController.playbackState) {
        case SRGMediaPlayerPlaybackStatePlaying: {
            [self notify:CSStreamSensePlay position:[self currentPositionInMilliseconds] labels:nil];
            break;
        }
            
        case SRGMediaPlayerPlaybackStateSeeking:
        case SRGMediaPlayerPlaybackStatePaused: {
            [self notify:CSStreamSensePause position:[self currentPositionInMilliseconds] labels:nil];
            break;
        }
            
        case SRGMediaPlayerPlaybackStateStalled: {
            [self notify:CSStreamSenseBuffer position:[self currentPositionInMilliseconds] labels:nil];
            break;
        }
            
        case SRGMediaPlayerPlaybackStateEnded: {
            [self notify:CSStreamSenseEnd position:[self currentPositionInMilliseconds] labels:nil];
            break;
        }
            
        default: {
            break;
        }
    }
}

- (void)segmentDidStart:(NSNotification *)notification
{

}

- (void)segmentDidEnd:(NSNotification *)notification
{

}

@end

#pragma mark Static functions

__attribute__((constructor)) static void SRGMediaPlayerTrackerInit(void)
{
    // Observe state changes for all media player controllers to create and remove trackers on the fly
    [[NSNotificationCenter defaultCenter] addObserver:[SRGMediaPlayerTracker class]
                                             selector:@selector(playbackStateDidChange:)
                                                 name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                               object:nil];
    
    s_trackers = [NSMutableDictionary dictionary];
}
