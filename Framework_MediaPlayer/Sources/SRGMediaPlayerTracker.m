//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerTracker.h"

@interface SRGMediaPlayerTracker ()

@property (nonatomic, weak) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation SRGMediaPlayerTracker

#pragma mark

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

#pragma mark Notifications

- (void)playbackStateDidChange:(NSNotification *)notification
{

}

- (void)segmentDidStart:(NSNotification *)notification
{

}

- (void)segmentDidEnd:(NSNotification *)notification
{

}

@end
