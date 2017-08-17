//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerTracker.h"

#import "NSMutableDictionary+SRGAnalytics.h"
#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsSegment.h"
#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

#import <ComScore/ComScore.h>
#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGAnalytics/SRGAnalytics.h>

static void *s_kvoContext = &s_kvoContext;

NSString * const SRGAnalyticsMediaPlayerLabelsKey = @"SRGAnalyticsMediaPlayerLabelsKey";

static long SRGAnalyticsCMTimeToMilliseconds(CMTime time)
{
    return (long)fmax(floor(CMTimeGetSeconds(time) * 1000.), 0.);
}

static SRGAnalyticsPlayerState SRGAnalyticsPlayerStateForPlaybackState(SRGMediaPlayerPlaybackState playbackState)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSNumber *> *s_playerStates;
    dispatch_once(&s_onceToken, ^{
        s_playerStates = @{ @(SRGMediaPlayerPlaybackStateIdle) : @(SRGAnalyticsPlayerStateStopped),
                      @(SRGMediaPlayerPlaybackStatePreparing) : @(SRGAnalyticsPlayerStateBuffering),
                      @(SRGMediaPlayerPlaybackStatePlaying) : @(SRGAnalyticsPlayerStatePlaying),
                      @(SRGMediaPlayerPlaybackStateSeeking) : @(SRGAnalyticsPlayerStateSeeking),
                      @(SRGMediaPlayerPlaybackStatePaused) : @(SRGAnalyticsPlayerStatePaused),
                      @(SRGMediaPlayerPlaybackStateStalled) : @(SRGAnalyticsPlayerStateBuffering),
                      @(SRGMediaPlayerPlaybackStateEnded) : @(SRGAnalyticsPlayerStateEnded) };
    });
    return s_playerStates[@(playbackState)].integerValue;
}

static NSMutableDictionary *s_trackers = nil;

@interface SRGMediaPlayerTracker () {
@private
    BOOL _enabled;
}

@property (nonatomic) SRGAnalyticsPlayerTracker *playerTracker;

// We must not retain the controller, so that its deallocation is not prevented (deallocation will ensure the idle state
// is always reached before the player gets destroyed, and our tracker is removed when this state is reached). Since
// returning to the idle state might occur during deallocation, we need a non-weak ref (which would otherwise be nilled
// and thus not available when the tracker is stopped)
@property (nonatomic, unsafe_unretained) SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic) NSTimer *heartbeatTimer;
@property (nonatomic) NSUInteger heartbeatCount;

@end

@implementation SRGMediaPlayerTracker

#pragma mark Object lifecycle

- (id)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (self = [super init]) {
        self.mediaPlayerController = mediaPlayerController;
        self.playerTracker = [[SRGAnalyticsPlayerTracker alloc] init];
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
    self.heartbeatTimer = nil;      // Invalidate timer
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Getters and setters

- (void)setHeartbeatTimer:(NSTimer *)heartbeatTimer
{
    [_heartbeatTimer invalidate];
    _heartbeatTimer = heartbeatTimer;
    self.heartbeatCount = 0;
}

#pragma mark Tracking

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
    
    @weakify(self)
    [self.mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, tracked) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        
        SRGAnalyticsPlayerState state = SRGAnalyticsPlayerStateForPlaybackState(self.mediaPlayerController.playbackState);
        [self updateWithState:state
                     position:[self currentPositionInMilliseconds]
                      segment:self.mediaPlayerController.selectedSegment
                     userInfo:nil];
    }];
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
    
    [self.mediaPlayerController removeObserver:self keyPath:@keypath(SRGMediaPlayerController.new, tracked)];
}

- (void)updateWithState:(SRGAnalyticsPlayerState)state position:(NSTimeInterval)position segment:(id<SRGSegment>)segment userInfo:(NSDictionary *)userInfo
{
    SRGAnalyticsPlayerLabels *playerLabels = [[SRGAnalyticsPlayerLabels alloc] init];
    playerLabels.playerName = @"SRGMediaPlayer";
    playerLabels.playerVersion = SRGMediaPlayerMarketingVersion();
    
    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
    AVMediaSelectionGroup *legibleGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelectionOption *currentLegibleOption = [playerItem selectedMediaOptionInMediaSelectionGroup:legibleGroup];
    playerLabels.subtitlesEnabled = @(currentLegibleOption != nil);
    
    if (userInfo) {
        playerLabels.timeshiftInMilliseconds = [self timeshiftInMillisecondsForStreamType:[userInfo[SRGMediaPlayerPreviousStreamTypeKey] integerValue]
                                                                                   timeRange:[userInfo[SRGMediaPlayerPreviousTimeRangeKey] CMTimeRangeValue]
                                                                                 currentTime:[userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue]];
    }
    else {
        playerLabels.timeshiftInMilliseconds = [self timeshiftInMilliseconds];
    }
    playerLabels.bandwidthInBitsPerSecond = [self bandwidthInBitsPerSecond];
    playerLabels.playerVolumeInPercent = [self playerVolumeInPercent];
    
    // comScore-only labels
    NSMutableDictionary<NSString *, NSString *> *comScoreCustomInfo = [NSMutableDictionary dictionary];
    [comScoreCustomInfo srg_safelySetString:[self windowState] forKey:@"ns_st_ws"];
    [comScoreCustomInfo srg_safelySetString:[self scalingMode] forKey:@"ns_st_sg"];
    [comScoreCustomInfo srg_safelySetString:[self orientation] forKey:@"ns_ap_ot"];
    playerLabels.comScoreCustomInfo = [comScoreCustomInfo copy];
    
    // comScore-only clip labels
    NSMutableDictionary<NSString *, NSString *> *comScoreCustomSegmentInfo = [NSMutableDictionary dictionary];
    [comScoreCustomSegmentInfo srg_safelySetString:[self dimensions] forKey:@"ns_st_cs"];
    [comScoreCustomSegmentInfo srg_safelySetString:[self screenType] forKey:@"srg_screen_type"];
    playerLabels.comScoreCustomSegmentInfo = [comScoreCustomSegmentInfo copy];
    
    SRGAnalyticsPlayerLabels *originalLabels = nil;
    if (userInfo) {
        NSDictionary *previousUserInfo = userInfo[SRGMediaPlayerPreviousUserInfoKey];
        originalLabels = previousUserInfo[SRGAnalyticsMediaPlayerLabelsKey];
    }
    else {
        originalLabels = self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey];
    }
    SRGAnalyticsPlayerLabels *fullLabels = [originalLabels copy] ?: [[SRGAnalyticsPlayerLabels alloc] init];
    [fullLabels mergeWithLabels:playerLabels];
    
    if ([segment conformsToProtocol:@protocol(SRGAnalyticsSegment)]) {
        SRGAnalyticsPlayerLabels *segmentLabels = [(id<SRGAnalyticsSegment>)segment srg_analyticsLabels];
        [fullLabels mergeWithLabels:segmentLabels];
    }
    
    // Restore the heartbeat timer when transitioning to play again
    if (state == SRGAnalyticsPlayerStatePlaying) {
        if (! self.heartbeatTimer) {
            SRGAnalyticsConfiguration *configuration = [SRGAnalyticsTracker sharedTracker].configuration;
            NSTimeInterval heartbeatInterval = configuration.unitTesting ? 3. : 30.;
            self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:heartbeatInterval
                                                                   target:self
                                                                 selector:@selector(heartbeat:)
                                                                 userInfo:nil
                                                                  repeats:YES];
        }
    }
    // Remove the heartbeat when not playing
    else if (state != SRGAnalyticsPlayerStateHeartbeat && state != SRGAnalyticsPlayerStateLiveHeartbeat) {
        self.heartbeatTimer = nil;
    }
    
    // Update tracking information
    if (self.mediaPlayerController.tracked && state != SRGAnalyticsPlayerStateStopped) {        
        [self.playerTracker updateWithPlayerState:state position:position labels:fullLabels];
    }
    else {
        [self.playerTracker updateWithPlayerState:SRGAnalyticsPlayerStateStopped position:position labels:fullLabels];
    }
}

#pragma mark Playback data

- (NSNumber *)bandwidthInBitsPerSecond
{
    AVPlayerItem *currentItem = self.mediaPlayerController.player.currentItem;
    if (! currentItem) {
        return nil;
    }
    
    NSArray<AVPlayerItemAccessLogEvent *> *events = currentItem.accessLog.events;
    if (! events.lastObject) {
        return nil;
    }
    
    double observedBitrate = events.lastObject.observedBitrate;
    return @(observedBitrate);
}

- (NSString *)windowState
{
    CGSize size = self.mediaPlayerController.playerLayer.videoRect.size;
    CGRect screenRect = [UIScreen mainScreen].bounds;
    return roundf(size.width) == roundf(screenRect.size.width) && roundf(size.height) == roundf(screenRect.size.height) ? @"full" : @"norm";
}

- (NSNumber *)playerVolumeInPercent
{
    // AVPlayer has a volume property, but its purpose is NOT end-user volume control (see documentation). This volume is
    // therefore not relevant for our calculations.
    AVPlayer *player = self.mediaPlayerController.player;
    if (! player || player.muted) {
        return nil;
    }
    // When we have a non-muted player, its volume is simply the system volume (note that this volume does not take
    // into account the ringer status).
    else {
        NSInteger volume = [AVAudioSession sharedInstance].outputVolume * 100;
        return @(volume);
    }
}

- (NSString *)scalingMode
{
    static NSDictionary<NSString *, NSString *> *s_gravities;
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
    static NSDictionary<NSNumber *, NSString *> *s_orientations;
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

- (NSNumber *)timeshiftInMilliseconds
{
    return [self timeshiftInMillisecondsForStreamType:self.mediaPlayerController.streamType
                                            timeRange:self.mediaPlayerController.timeRange
                                          currentTime:self.mediaPlayerController.player.currentItem.currentTime];
}

- (NSNumber *)timeshiftInMillisecondsForStreamType:(SRGMediaPlayerStreamType)streamType timeRange:(CMTimeRange)timeRange currentTime:(CMTime)currentTime
{
    // Do not return any value for non-live streams
    if (streamType == SRGMediaPlayerStreamTypeDVR) {
        CMTime timeShift = CMTimeSubtract(CMTimeRangeGetEnd(timeRange), currentTime);
        NSInteger timeShiftInSeconds = (NSInteger)fabs(CMTimeGetSeconds(timeShift));
        
        // Consider offsets smaller than the tolerance to be equivalent to live conditions, sending 0 instead of the real offset
        if (timeShiftInSeconds <= self.mediaPlayerController.liveTolerance) {
            return @0;
        }
        else {
            return @(timeShiftInSeconds * 1000);
        }
    }
    else if (streamType == SRGMediaPlayerStreamTypeLive) {
        return @0;
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

- (long)currentPositionInMilliseconds
{
    CMTime currentTime = [self.mediaPlayerController.player.currentItem currentTime];
    if (CMTIME_IS_INDEFINITE(currentTime) || CMTIME_IS_INVALID(currentTime)) {
        return 0;
    }
    else {
        return SRGAnalyticsCMTimeToMilliseconds(currentTime);
    }
}

#pragma mark Notifications

+ (void)playbackStateDidChange:(NSNotification *)notification
{
    if (! [SRGAnalyticsTracker sharedTracker].configuration) {
        return;
    }
    
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
        [tracker updateWithState:SRGAnalyticsPlayerStateBuffering
                        position:0
                         segment:mediaPlayerController.selectedSegment
                        userInfo:nil];
        
        SRGAnalyticsLogInfo(@"PlayerTracker", @"Started tracking for %@", key);
    }
    else if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        SRGMediaPlayerTracker *tracker = s_trackers[key];
        NSAssert(tracker != nil, @"A tracker must exist");
        
        NSTimeInterval lastPosition = SRGAnalyticsCMTimeToMilliseconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue]);
        [tracker updateWithState:SRGAnalyticsPlayerStateStopped
                        position:lastPosition
                         segment:mediaPlayerController.selectedSegment
                        userInfo:notification.userInfo];
        [tracker stop];
        
        [s_trackers removeObjectForKey:key];
        if (s_trackers.count == 0) {
            [CSComScore onUxInactive];
        }
        
        SRGAnalyticsLogInfo(@"PlayerTracker", @"Stopped tracking for %@", key);
    }
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerController *mediaPlayerController = self.mediaPlayerController;
    SRGMediaPlayerPlaybackState playbackState = mediaPlayerController.playbackState;
    NSAssert(playbackState != SRGMediaPlayerPlaybackStateIdle && playbackState != SRGMediaPlayerPlaybackStatePreparing, @"Notification registrations are managed in idle and preparing states and should therefore not be recorded as notification");
    
    // Inhibit usual playback transitions occuring during segment selection
    if ([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]) {
        return;
    }
    
    if (playbackState == SRGMediaPlayerPlaybackStatePlaying) {
        self.playerTracker.livestream = (mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive) || (mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR);
    }
    
    [self updateWithState:SRGAnalyticsPlayerStateForPlaybackState(playbackState)
                 position:[self currentPositionInMilliseconds]
                  segment:mediaPlayerController.selectedSegment
                 userInfo:nil];
}

- (void)segmentDidStart:(NSNotification *)notification
{
    // Only send analytics for segment selections
    if ([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        
        // Notify full-length end (only if not starting at the given segment, i.e. if the player is not preparing playback)
        id<SRGSegment> previousSegment = notification.userInfo[SRGMediaPlayerPreviousSegmentKey];
        if (! previousSegment && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePreparing) {
            NSTimeInterval lastPosition = SRGAnalyticsCMTimeToMilliseconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue]);
            [self updateWithState:SRGAnalyticsPlayerStateStopped
                         position:lastPosition
                          segment:nil
                         userInfo:nil];
        }
        
        [self updateWithState:SRGAnalyticsPlayerStatePlaying
                     position:[self currentPositionInMilliseconds]
                      segment:segment
                     userInfo:nil];
    }
}

- (void)segmentDidEnd:(NSNotification *)notification
{
    // Only send analytics for segments which were selected
    if ([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]) {
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        NSValue *lastPlaybackTimeValue = notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey];
        NSTimeInterval lastPositionInMilliseconds = SRGAnalyticsCMTimeToMilliseconds([lastPlaybackTimeValue CMTimeValue]);
        
        // Notify full-length start if the transition was not due to another segment being selected
        if (! [notification.userInfo[SRGMediaPlayerSelectionKey] boolValue] && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded) {
            SRGAnalyticsPlayerState endState = [notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue] ? SRGAnalyticsPlayerStateStopped : SRGAnalyticsPlayerStateEnded;
            NSTimeInterval endPosition = (endState == SRGAnalyticsPlayerStateStopped) ? lastPositionInMilliseconds : [self currentPositionInMilliseconds];
            
            [self updateWithState:endState
                         position:endPosition
                          segment:segment
                         userInfo:nil];
            [self updateWithState:SRGAnalyticsPlayerStatePlaying
                         position:[self currentPositionInMilliseconds]
                          segment:nil
                         userInfo:nil];
        }
        else {
            [self updateWithState:SRGAnalyticsPlayerStateStopped
                         position:lastPositionInMilliseconds
                          segment:segment
                         userInfo:nil];
        }
    }
}

#pragma mark Timers

- (void)heartbeat:(NSTimer *)timer
{
    NSAssert(self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying, @"Heartbeat timer is only active when playing by construction");
    
    [self updateWithState:SRGAnalyticsPlayerStateHeartbeat 
                 position:[self currentPositionInMilliseconds]
                  segment:self.mediaPlayerController.selectedSegment
                 userInfo:nil];
    
    // Send a live heartbeat each minute
    if (self.mediaPlayerController.live && self.heartbeatCount % 2 == 0) {
        [self updateWithState:SRGAnalyticsPlayerStateLiveHeartbeat
                     position:[self currentPositionInMilliseconds] 
                      segment:self.mediaPlayerController.selectedSegment
                     userInfo:nil];
    }
    
    self.heartbeatCount += 1;
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
