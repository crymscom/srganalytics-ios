//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerTracker.h"

#import "SRGAnalyticsSegment.h"
#import "SRGMediaPlayerController+SRGAnalytics.h"

#import <SRGAnalytics/SRGAnalytics.h>

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
        
        // The default keep-alive time interval of 20 minutes is too big. Set it to 9 minutes
        [self setKeepAliveInterval:9 * 60];
        
        // Global labels
        [self safelySetValue:@"SRGMediaPlayer" forLabel:@"ns_st_mp"];
        [self safelySetValue:SRGAnalyticsMarketingVersion() forLabel:@"ns_st_pu"];
        [self safelySetValue:SRGMediaPlayerMarketingVersion() forLabel:@"ns_st_mv"];
        [self safelySetValue:@"c" forLabel:@"ns_st_it"];
        
        [self safelySetValue:[SRGAnalyticsTracker sharedTracker].comScoreVirtualSite forLabel:@"ns_vsite"];
        [self safelySetValue:@"p_app_ios" forLabel:@"srg_ptype"];
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
    // FIXME: Due to internal comScore bugs, the object will never be properly released. This does not hurt in our implementaton,
    //        but this could be fixed
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
    
    [self notifyEvent:CSStreamSenseBuffer withPosition:[self currentPositionInMilliseconds] segment:nil];
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
    
    [self notifyEvent:CSStreamSenseEnd withPosition:[self currentPositionInMilliseconds] segment:nil];
}

#pragma mark Helpers

- (void)safelySetValue:(NSString *)value forLabel:(NSString *)label
{
    NSParameterAssert(label);
    
    if (value) {
        [self setLabel:label value:value];
    }
    else {
        [[self labels] removeObjectForKey:label];
    }
}

- (void)safelySetValue:(NSString *)value forClipLabel:(NSString *)label
{
    NSParameterAssert(label);
    
    if (value) {
        [[self clip] setLabel:label value:value];
    }
    else {
        [[[self clip] labels] removeObjectForKey:label];
    }
}

- (void)notifyEvent:(CSStreamSenseEventType)event withPosition:(long)position segment:(id<SRGSegment>)segment
{
    // Labels
    [self safelySetValue:[self bitRate] forLabel:@"ns_st_br"];
    [self safelySetValue:[self windowState] forLabel:@"ns_st_ws"];
    [self safelySetValue:[self volume] forLabel:@"ns_st_vo"];
    [self safelySetValue:[self scalingMode] forLabel:@"ns_st_sg"];
    [self safelySetValue:[self orientation] forLabel:@"ns_ap_ot"];
    
    if (self.mediaPlayerController.srg_analyticsLabels) {
        [self setLabels:self.mediaPlayerController.srg_analyticsLabels];
    }
    
    // Clip labels
    [self safelySetValue:[self dimensions] forClipLabel:@"ns_st_cs"];
    [self safelySetValue:[self timeshiftFromLiveInMilliseconds] forClipLabel:@"srg_timeshift"];
    [self safelySetValue:[self screenType] forClipLabel:@"srg_screen_type"];
    
    if ([segment conformsToProtocol:@protocol(SRGAnalyticsSegment)]) {
        NSDictionary *labels = [(id<SRGAnalyticsSegment>)segment srg_analyticsLabels];
        if (labels) {
            [[self clip] setLabels:labels];
        }
    }
    
    [self notify:event position:position labels:nil /* already set on the stream and clip objects */];
}

#pragma mark Playback data

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

- (NSString *)bitRate
{
    AVPlayerItem *currentItem = self.mediaPlayerController.player.currentItem;
    if (! currentItem) {
        return nil;
    }
    
    NSArray *events = currentItem.accessLog.events;
    if (! events.lastObject) {
        return nil;
    }
    
    double observedBitrate = [events.lastObject observedBitrate];
    return [@(observedBitrate) stringValue];
}

- (NSString *)windowState
{
    CGSize size = self.mediaPlayerController.playerLayer.videoRect.size;
    CGRect screenRect = [UIScreen mainScreen].bounds;
    return roundf(size.width) == roundf(screenRect.size.width) && roundf(size.height) == roundf(screenRect.size.height) ? @"full" : @"norm";
}

- (NSString *)volume
{
    if (self.mediaPlayerController.player && self.mediaPlayerController.player.isMuted) {
        return @"0";
    }
    else {
        NSInteger volume = [AVAudioSession sharedInstance].outputVolume * 100;
        return [@(volume) stringValue];
    }
}

- (NSString *)scalingMode
{
    static NSDictionary *s_gravities;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_gravities = @{ AVLayerVideoGravityResize: @"fill",
                         AVLayerVideoGravityResizeAspect : @"fit-a",
                         AVLayerVideoGravityResizeAspectFill : @"fill-a" };
    });
    return s_gravities[self.mediaPlayerController.playerLayer.videoGravity] ?: @"no";
}

- (NSString *)orientation
{
    static NSDictionary *s_orientations;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_orientations = @{ @(UIDeviceOrientationFaceDown) : @"facedown",
                            @(UIDeviceOrientationFaceUp) : @"faceup",
                            @(UIDeviceOrientationPortrait) : @"pt",
                            @(UIDeviceOrientationPortraitUpsideDown) : @"updown",
                            @(UIDeviceOrientationLandscapeLeft) : @"left",
                            @(UIDeviceOrientationLandscapeRight) : @"right" };
    });
    return s_orientations[@([UIDevice currentDevice].orientation)];
}

- (NSString *)dimensions
{
    CGSize size = self.mediaPlayerController.playerLayer.videoRect.size;
    return [NSString stringWithFormat:@"%0.fx%0.f", size.width, size.height];
}

- (NSString *)timeshiftFromLiveInMilliseconds
{
    // Do not return any value for non-live streams
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        CMTime timeShift = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), self.mediaPlayerController.player.currentItem.currentTime);
        NSInteger timeShiftInSeconds = (NSInteger)fabs(CMTimeGetSeconds(timeShift));
        
        // Consider offsets smaller than the tolerance to be equivalent to live conditions, sending 0 instead of the real offset
        if (timeShiftInSeconds <= self.mediaPlayerController.liveTolerance) {
            return @"0";
        }
        else {
            return [@(timeShiftInSeconds * 1000) stringValue];
        }
    }
    else if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive) {
        return @"0";
    }
    else {
        return nil;
    }
}

- (NSString *)airplay
{
    return self.mediaPlayerController.player.isExternalPlaybackActive ? @"1" : @"0";
}

- (NSString *)screenType
{
    if (self.mediaPlayerController.pictureInPictureController.pictureInPictureActive) {
        return @"pip";
    }
    else if (self.mediaPlayerController.player.isExternalPlaybackActive) {
        return @"airplay";
    }
    else {
        return @"default";
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

- (void)playbackStateDidChange:(NSNotification *)notification
{
    switch (self.mediaPlayerController.playbackState) {
        case SRGMediaPlayerPlaybackStatePlaying: {
            [self notifyEvent:CSStreamSensePlay withPosition:[self currentPositionInMilliseconds] segment:nil];
            break;
        }
            
        case SRGMediaPlayerPlaybackStateSeeking:
        case SRGMediaPlayerPlaybackStatePaused: {
            [self notifyEvent:CSStreamSensePause withPosition:[self currentPositionInMilliseconds] segment:nil];
            break;
        }
            
        case SRGMediaPlayerPlaybackStateStalled: {
            [self notifyEvent:CSStreamSenseBuffer withPosition:[self currentPositionInMilliseconds] segment:nil];
            break;
        }
            
        case SRGMediaPlayerPlaybackStateEnded: {
            [self notifyEvent:CSStreamSenseEnd withPosition:[self currentPositionInMilliseconds] segment:nil];
            break;
        }
            
        default: {
            break;
        }
    }
}

- (void)segmentDidStart:(NSNotification *)notification
{
    // Only send analytics for selected segments
    if ([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        
        // Notify full-length end (only if not started at the given segment, i.e. if the player is not preparing playback)
        id<SRGSegment> previousSegment = notification.userInfo[SRGMediaPlayerPreviousSegmentKey];
        if (! previousSegment && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePreparing) {
            [self notifyEvent:CSStreamSenseEnd withPosition:CMTimeGetSeconds(segment.timeRange.start) * 1000. segment:nil];
        }
        
        [self notifyEvent:CSStreamSensePlay withPosition:CMTimeGetSeconds(segment.timeRange.start) * 1000. segment:segment];
    }
}

- (void)segmentDidEnd:(NSNotification *)notification
{
    // Only send analytics for selected segments
    if ([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        
        [self notifyEvent:CSStreamSenseEnd withPosition:CMTimeGetSeconds(CMTimeRangeGetEnd(segment.timeRange)) * 1000. segment:segment];
        
        // Notify full-length start
        // TODO: Check playback end condition with a unit test
        id<SRGSegment> nextSegment = notification.userInfo[SRGMediaPlayerNextSegmentKey];
        if (! nextSegment && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded) {
            [self notifyEvent:CSStreamSensePlay withPosition:CMTimeGetSeconds(CMTimeRangeGetEnd(segment.timeRange)) * 1000. segment:nil];
        }
    }
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
