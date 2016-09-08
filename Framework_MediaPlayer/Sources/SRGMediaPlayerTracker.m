//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerTracker.h"

@interface SRGMediaPlayerTracker ()

@property (nonatomic, weak) SRGMediaPlayerController *mediaPlayerController;

@end

__attribute__((constructor)) static void SRGMediaPlayerTrackerInit(void);

@implementation SRGMediaPlayerTracker

#pragma mark Object lifecycle

- (id)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (self = [super init]) {
        self.mediaPlayerController = mediaPlayerController;
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithMediaPlayerController:nil];
}

#pragma clang diagnostic pop

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:SRGMediaPlayerPlaybackStateDidChangeNotification object:_mediaPlayerController];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:SRGMediaPlayerSegmentDidStartNotification object:_mediaPlayerController];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:SRGMediaPlayerSegmentDidEndNotification object:_mediaPlayerController];
    }
    
    _mediaPlayerController = mediaPlayerController;
    
    if (mediaPlayerController) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateDidChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(segmentDidStart:)
                                                     name:SRGMediaPlayerSegmentDidStartNotification
                                                   object:mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(segmentDidEnd:)
                                                     name:SRGMediaPlayerSegmentDidEndNotification
                                                   object:mediaPlayerController];
    }
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
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        // TODO: Attach tracker. Must send initial buffer event
    }
    else if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        // TODO: Detach tracker
    }
    
     // TODO: Call onUxActive / onUxInactive when number of tracker changes from 0 -> 1 / 1 -> 0
}

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
}
