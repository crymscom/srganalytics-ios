//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerTracker.h"

#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsSegment.h"
#import "SRGAnalyticsTracker.h"
#import "SRGAnalyticsTracker+Private.h"
#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGAnalytics/SRGAnalytics.h>

typedef NS_ENUM(NSInteger, SRGAnalyticsMediaEvent) {
    SRGAnalyticsMediaEventBuffer,
    SRGAnalyticsMediaEventPlay,
    SRGAnalyticsMediaEventPause,
    SRGAnalyticsMediaEventSeek,
    SRGAnalyticsMediaEventStop,
    SRGAnalyticsMediaEventEnd,
    SRGAnalyticsMediaEventHeartbeat
};

static void *s_kvoContext = &s_kvoContext;

NSString * const SRGAnalyticsMediaPlayerLabelsKey = @"SRGAnalyticsMediaPlayerLabelsKey";

static NSMutableDictionary *s_trackers = nil;

@interface SRGMediaPlayerTracker () {
@private
    BOOL _enabled;
}

// We must not retain the controller, so that its deallocation is not prevented (deallocation will ensure the idle state
// is always reached before the player gets destroyed, and our tracker is removed when this state is reached). Since
// returning to the idle state might occur during deallocation, we need a non-weak ref (which would otherwise be nilled
// and thus not available when the tracker is stopped)
@property (nonatomic, unsafe_unretained) SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic) NSDictionary<NSString *, NSString *> *currentLabels;
@property (nonatomic) NSTimer *heartbeatTimer;

@property (nonatomic, weak) id periodicTimeObserver;
@property (nonatomic) long positionInMilliseconds;
@property (nonatomic) NSDictionary<NSString *, NSString *> *labels;

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

#pragma mark Getters and setters

- (void)setHeartbeatTimer:(NSTimer *)heartbeatTimer
{
    [_heartbeatTimer invalidate];
    _heartbeatTimer = heartbeatTimer;
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
    
    [self notifyEvent:SRGAnalyticsMediaEventBuffer withPosition:0 labels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey] segment:nil];
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, tracked) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        
        // Balance events if the player is playing, so that all events can be properly emitted
        if (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
            SRGAnalyticsMediaEvent event = self.mediaPlayerController.tracked ? SRGAnalyticsMediaEventPlay : SRGAnalyticsMediaEventEnd;
            [self rawNotifyEvent:event
                    withPosition:[self currentPositionInMilliseconds]
                          labels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                         segment:self.mediaPlayerController.selectedSegment];
        }
        else if (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateSeeking
                 || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePaused) {
            SRGAnalyticsMediaEvent event = self.mediaPlayerController.tracked ? SRGAnalyticsMediaEventPlay : SRGAnalyticsMediaEventEnd;
            [self rawNotifyEvent:event
                    withPosition:[self currentPositionInMilliseconds]
                          labels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                         segment:self.mediaPlayerController.selectedSegment];
            
            // Also send the pause event when starting tracking, so that the current player state is accurately reflected
            if (self.mediaPlayerController.tracked) {
                [self rawNotifyEvent:SRGAnalyticsMediaEventPause
                        withPosition:[self currentPositionInMilliseconds]
                              labels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                             segment:self.mediaPlayerController.selectedSegment];
            }
        }
    }];
    
    self.periodicTimeObserver = [self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:nil usingBlock:^(CMTime time) {
        @strongify(self)
        
        self.positionInMilliseconds = CMTimeGetSeconds(time) * 1000;
    }];
    self.positionInMilliseconds = 0;
    
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:30. target:self selector:@selector(heartbeat:) userInfo:nil repeats:YES];
}

- (void)stop
{
    NSAssert(self.mediaPlayerController, @"Media player controller must be available when stopping");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                  object:self.mediaPlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SRGMediaPlayerSegmentDidStartNotification
                                                  object:self.mediaPlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SRGMediaPlayerSegmentDidEndNotification
                                                  object:self.mediaPlayerController];
    
    // The position in milliseconds must not be 0 when the player is stopped (Webtrekk requirement). Track it since the
    // value retrieved from the player would be 0 (idle state, player is nil)
    [self notifyEvent:SRGAnalyticsMediaEventEnd withPosition:self.positionInMilliseconds labels:self.labels segment:self.mediaPlayerController.selectedSegment];
    
    [self.mediaPlayerController removeObserver:self keyPath:@keypath(SRGMediaPlayerController.new, tracked)];
    [self.mediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
    
    self.positionInMilliseconds = 0;
    self.labels = nil;
    
    self.heartbeatTimer = nil;
    self.mediaPlayerController = nil;
}

#pragma mark Helpers

- (void)notifyEvent:(SRGAnalyticsMediaEvent)event withPosition:(long)position labels:(NSDictionary *)labels segment:(id<SRGSegment>)segment
{
    if (! self.mediaPlayerController.tracked) {
        return;
    }
    
    self.currentLabels = labels;
    
    [self rawNotifyEvent:event withPosition:position labels:labels segment:segment];
}

// Raw notification implementation which does not check whether the tracker is enabled
- (void)rawNotifyEvent:(SRGAnalyticsMediaEvent)event withPosition:(long)position labels:(NSDictionary *)labels segment:(id<SRGSegment>)segment
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_actions;
    dispatch_once(&s_onceToken, ^{
        s_actions = @{ @(SRGAnalyticsMediaEventPlay) : @"play",
                       @(SRGAnalyticsMediaEventPause) : @"pause",
                       @(SRGAnalyticsMediaEventSeek) : @"seek",
                       @(SRGAnalyticsMediaEventStop) : @"stop",
                       @(SRGAnalyticsMediaEventEnd) : @"eof",
                       @(SRGAnalyticsMediaEventHeartbeat) : @"pos"};
    });
    
    NSString *action = s_actions[@(event)];
    if (! action) {
        return;
    }
    
    TagCommander *tagCommander = [SRGAnalyticsTracker sharedTracker].tagCommander;
    [tagCommander addData:@"HIT_TYPE" withValue:@"click"];
    [tagCommander addData:@"VIDEO_ACTION" withValue:action];
    [tagCommander addData:@"VIDEO_CURRENT_POSITION" withValue:@((int)(position / 1000)).stringValue];
    [tagCommander addData:@"VIDEO_VOLUME" withValue:[self volume]];
    [tagCommander addData:@"VIDEO_MUTE" withValue:[self muted]];
    
    NSMutableDictionary<NSString *, NSString *> *allLabels = [labels mutableCopy];
    [labels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [tagCommander addData:key withValue:object];
    }];
    
    if ([segment conformsToProtocol:@protocol(SRGAnalyticsSegment)]) {
        NSDictionary *segmentLabels = [(id<SRGAnalyticsSegment>)segment srg_analyticsLabels];
        
        if (segmentLabels) {
            [allLabels addEntriesFromDictionary:segmentLabels];
            [segmentLabels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
                [tagCommander addData:key withValue:object];
            }];
        }
    }
    
    self.labels = [allLabels copy];
    
    [tagCommander sendData];
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
        if (CMTIME_IS_INDEFINITE(currentTime) || CMTIME_IS_INVALID(currentTime)) {
            return 0;
        }
        else {
            return (long)floor(CMTimeGetSeconds(currentTime) * 1000.);
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

- (NSString *)muted
{
    return self.mediaPlayerController.player.muted ? @"1" : @"0";
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
    // Avoid calling tracking methods when the tracker is not started (which usually leads to crashes because the virtual
    // site has not been set)
    if (! [SRGAnalyticsTracker sharedTracker].started) {
        return;
    }
    
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    
    NSValue *key = [NSValue valueWithNonretainedObject:mediaPlayerController];
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        NSAssert(s_trackers[key] == nil, @"No tracker must exist");
        SRGMediaPlayerTracker *tracker = [[SRGMediaPlayerTracker alloc] initWithMediaPlayerController:mediaPlayerController];
        
        s_trackers[key] = tracker;
        
        [tracker start];
        
        SRGAnalyticsLogInfo(@"PlayerTracker", @"Started tracking for %@", key);
    }
    else if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        SRGMediaPlayerTracker *tracker = s_trackers[key];
        NSAssert(tracker != nil, @"A tracker must exist");
        
        [tracker stop];
        
        [s_trackers removeObjectForKey:key];
        
        SRGAnalyticsLogInfo(@"PlayerTracker", @"Stopped tracking for %@", key);
    }
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    // Inhibit usual playback transitions occuring during segment selection
    if ([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]) {
        return;
    }
    
    SRGAnalyticsMediaEvent event;
    switch (self.mediaPlayerController.playbackState) {
        case SRGMediaPlayerPlaybackStatePlaying: {
            event = SRGAnalyticsMediaEventPlay;
            break;
        }
            
        case SRGMediaPlayerPlaybackStateSeeking:
            event = SRGAnalyticsMediaEventSeek;
            break;
            
        case SRGMediaPlayerPlaybackStatePaused: {
            event = SRGAnalyticsMediaEventPause;
            break;
        }
            
        case SRGMediaPlayerPlaybackStateStalled: {
            event = SRGAnalyticsMediaEventBuffer;
            break;
        }
            
        case SRGMediaPlayerPlaybackStateEnded: {
            event = SRGAnalyticsMediaEventEnd;
            break;
        }
            
        case SRGMediaPlayerPlaybackStateIdle: {
            event = SRGAnalyticsMediaEventStop;
            break;
        }
            
        default: {
            return;
            break;
        }
    }
    
    [self notifyEvent:event
         withPosition:[self currentPositionInMilliseconds]
               labels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
              segment:self.mediaPlayerController.selectedSegment];
}

- (void)segmentDidStart:(NSNotification *)notification
{
    // Only send analytics for segment selections
    if ([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        
        // Notify full-length end (only if not starting at the given segment, i.e. if the player is not preparing playback)
        id<SRGSegment> previousSegment = notification.userInfo[SRGMediaPlayerPreviousSegmentKey];
        if (! previousSegment && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePreparing) {
            [self notifyEvent:SRGAnalyticsMediaEventEnd
                 withPosition:CMTimeGetSeconds(segment.srg_timeRange.start) * 1000.
                       labels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                      segment:nil];
        }
        
        [self notifyEvent:SRGAnalyticsMediaEventPlay
             withPosition:CMTimeGetSeconds(segment.srg_timeRange.start) * 1000.
                   labels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                  segment:segment];
    }
}

- (void)segmentDidEnd:(NSNotification *)notification
{
    // Only send analytics for segments which were selected
    if ([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        
        [self notifyEvent:SRGAnalyticsMediaEventEnd
             withPosition:CMTimeGetSeconds(CMTimeRangeGetEnd(segment.srg_timeRange)) * 1000.
                   labels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                  segment:segment];
        
        // Notify full-length start if the transition was not due to another segment being selected
        if (! [notification.userInfo[SRGMediaPlayerSelectionKey] boolValue] && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded) {
            [self notifyEvent:SRGAnalyticsMediaEventPlay
                 withPosition:CMTimeGetSeconds(CMTimeRangeGetEnd(segment.srg_timeRange)) * 1000.
                       labels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                      segment:nil];
        }
    }
}

#pragma mark Timers

- (void)heartbeat:(NSTimer *)timer
{
    if (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
        [self notifyEvent:SRGAnalyticsMediaEventHeartbeat
             withPosition:[self currentPositionInMilliseconds]
                   labels:self.currentLabels
                  segment:self.mediaPlayerController.selectedSegment];
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
