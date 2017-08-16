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

static SRGAnalyticsPlayerEvent SRGAnalyticsPlayerEventForPlaybackState(SRGMediaPlayerPlaybackState playbackState)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSNumber *> *s_events;
    dispatch_once(&s_onceToken, ^{
        s_events = @{ @(SRGMediaPlayerPlaybackStateIdle) : @(SRGAnalyticsPlayerEventStop),
                      @(SRGMediaPlayerPlaybackStatePreparing) : @(SRGAnalyticsPlayerEventBuffer),
                      @(SRGMediaPlayerPlaybackStatePlaying) : @(SRGAnalyticsPlayerEventPlay),
                      @(SRGMediaPlayerPlaybackStateSeeking) : @(SRGAnalyticsPlayerEventSeek),
                      @(SRGMediaPlayerPlaybackStatePaused) : @(SRGAnalyticsPlayerEventPause),
                      @(SRGMediaPlayerPlaybackStateStalled) : @(SRGAnalyticsPlayerEventBuffer),
                      @(SRGMediaPlayerPlaybackStateEnded) : @(SRGAnalyticsPlayerEventEnd) };
    });
    return s_events[@(playbackState)].integerValue;
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

@property (nonatomic, readonly) long currentPositionInMilliseconds;

@property (nonatomic) NSTimer *heartbeatTimer;
@property (nonatomic) NSUInteger heartbeatCount;

@property (nonatomic) SRGAnalyticsPlayerLabels *recentLabels;
@property (nonatomic) id<SRGSegment> recentSegment;

@end

@implementation SRGMediaPlayerTracker

@synthesize currentPositionInMilliseconds = _currentPositionInMilliseconds;

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

- (long)currentPositionInMilliseconds
{
    // Live stream: Playhead position must be always 0
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive || self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        return 0;
    }
    else {
        CMTime currentTime = [self.mediaPlayerController.player.currentItem currentTime];
        if (CMTIME_IS_INDEFINITE(currentTime) || CMTIME_IS_INVALID(currentTime)) {
            return 0;
        }
        else {
            return SRGAnalyticsCMTimeToMilliseconds(currentTime);
        }
    }
}

#pragma mark Tracking

- (void)trackEvent:(SRGAnalyticsPlayerEvent)event atPosition:(NSTimeInterval)position withLabels:(SRGAnalyticsPlayerLabels *)labels segment:(id<SRGSegment>)segment
{
    SRGAnalyticsPlayerLabels *playerLabels = [[SRGAnalyticsPlayerLabels alloc] init];
    playerLabels.playerName = @"SRGMediaPlayer";
    playerLabels.playerVersion = SRGMediaPlayerMarketingVersion();
    
    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
    AVMediaSelectionGroup *legibleGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelectionOption *currentLegibleOption = [playerItem selectedMediaOptionInMediaSelectionGroup:legibleGroup];
    playerLabels.subtitlesEnabled = @(currentLegibleOption != nil);
    
    playerLabels.timeshiftInMilliseconds = [self timeshiftInMilliseconds];
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
    
    SRGAnalyticsPlayerLabels *fullLabels = labels ? [labels copy] : [[SRGAnalyticsPlayerLabels alloc] init];
    [fullLabels mergeWithLabels:playerLabels];
    
    if ([segment conformsToProtocol:@protocol(SRGAnalyticsSegment)]) {
        SRGAnalyticsPlayerLabels *segmentLabels = [(id<SRGAnalyticsSegment>)segment srg_analyticsLabels];
        [fullLabels mergeWithLabels:segmentLabels];
    }
    
    if (self.mediaPlayerController.tracked && event != SRGAnalyticsPlayerEventStop) {
        if (! self.heartbeatTimer && event == SRGAnalyticsPlayerEventPlay) {
            SRGAnalyticsConfiguration *configuration = [SRGAnalyticsTracker sharedTracker].configuration;
            NSTimeInterval heartbeatInterval = configuration.unitTesting ? 3. : 30.;
            self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:heartbeatInterval
                                                                   target:self
                                                                 selector:@selector(heartbeat:)
                                                                 userInfo:nil
                                                                  repeats:YES];
        }
        
        self.recentLabels = labels;
        self.recentSegment = segment;
        
        [self.playerTracker trackPlayerEvent:event atPosition:position withLabels:fullLabels];
    }
    else {
        self.heartbeatTimer = nil;
        
        self.recentLabels = nil;
        self.recentSegment = nil;
        
        [self.playerTracker trackPlayerEvent:SRGAnalyticsPlayerEventStop atPosition:position withLabels:fullLabels];
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
    // Do not return any value for non-live streams
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        CMTime timeShift = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), self.mediaPlayerController.player.currentItem.currentTime);
        NSInteger timeShiftInSeconds = (NSInteger)fabs(CMTimeGetSeconds(timeShift));
        
        // Consider offsets smaller than the tolerance to be equivalent to live conditions, sending 0 instead of the real offset
        if (timeShiftInSeconds <= self.mediaPlayerController.liveTolerance) {
            return @0;
        }
        else {
            return @(timeShiftInSeconds * 1000);
        }
    }
    else if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive) {
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
        
        [[NSNotificationCenter defaultCenter] addObserver:tracker
                                                 selector:@selector(playbackStateDidChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:tracker
                                                 selector:@selector(segmentDidStart:)
                                                     name:SRGMediaPlayerSegmentDidStartNotification
                                                   object:mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:tracker
                                                 selector:@selector(segmentDidEnd:)
                                                     name:SRGMediaPlayerSegmentDidEndNotification
                                                   object:mediaPlayerController];
        
        @weakify(mediaPlayerController)
        [mediaPlayerController addObserver:tracker keyPath:@keypath(SRGMediaPlayerController.new, tracked) options:0 block:^(MAKVONotification *notification) {
            @strongify(mediaPlayerController)
            
            [tracker trackEvent:SRGAnalyticsPlayerEventForPlaybackState(mediaPlayerController.playbackState)
                     atPosition:tracker.currentPositionInMilliseconds
                     withLabels:mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                        segment:mediaPlayerController.selectedSegment];
        }];
        
        [tracker trackEvent:SRGAnalyticsPlayerEventBuffer
                 atPosition:0
                 withLabels:mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                    segment:mediaPlayerController.selectedSegment];
        
        SRGAnalyticsLogInfo(@"PlayerTracker", @"Started tracking for %@", key);
    }
    else if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        SRGMediaPlayerTracker *tracker = s_trackers[key];
        NSAssert(tracker != nil, @"A tracker must exist");
        
        [[NSNotificationCenter defaultCenter] removeObserver:tracker
                                                        name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                      object:mediaPlayerController];
        [[NSNotificationCenter defaultCenter] removeObserver:tracker
                                                        name:SRGMediaPlayerSegmentDidStartNotification
                                                      object:mediaPlayerController];
        [[NSNotificationCenter defaultCenter] removeObserver:tracker
                                                        name:SRGMediaPlayerSegmentDidEndNotification
                                                      object:mediaPlayerController];
        
        [mediaPlayerController removeObserver:tracker keyPath:@keypath(SRGMediaPlayerController.new, tracked)];
        
        NSDictionary *previousUserInfo = notification.userInfo[SRGMediaPlayerPreviousUserInfoKey];
        NSTimeInterval lastPosition = SRGAnalyticsCMTimeToMilliseconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue]);
        [tracker trackEvent:SRGAnalyticsPlayerEventStop
                 atPosition:lastPosition
                 withLabels:previousUserInfo[SRGAnalyticsMediaPlayerLabelsKey]
                    segment:mediaPlayerController.selectedSegment];
        
        [s_trackers removeObjectForKey:key];
        if (s_trackers.count == 0) {
            [CSComScore onUxInactive];
        }
        
        SRGAnalyticsLogInfo(@"PlayerTracker", @"Stopped tracking for %@", key);
    }
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerPlaybackState playbackState = self.mediaPlayerController.playbackState;
    NSAssert(playbackState != SRGMediaPlayerPlaybackStateIdle && playbackState != SRGMediaPlayerPlaybackStatePreparing, @"Notification registrations are managed in idle and preparing states and should therefore not be recorded as notification");
    
    // Inhibit usual playback transitions occuring during segment selection
    if ([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]) {
        return;
    }
    
    [self trackEvent:SRGAnalyticsPlayerEventForPlaybackState(playbackState)
          atPosition:self.currentPositionInMilliseconds
          withLabels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
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
            NSTimeInterval lastPosition = SRGAnalyticsCMTimeToMilliseconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue]);
            [self trackEvent:SRGAnalyticsPlayerEventStop
                  atPosition:lastPosition
                  withLabels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                     segment:nil];
        }
        
        [self trackEvent:SRGAnalyticsPlayerEventPlay
              atPosition:self.currentPositionInMilliseconds
              withLabels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                 segment:segment];
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
            SRGAnalyticsPlayerEvent endEvent = [notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue] ? SRGAnalyticsPlayerEventStop : SRGAnalyticsPlayerEventEnd;
            NSTimeInterval endPosition = (endEvent == SRGAnalyticsPlayerEventStop) ? lastPositionInMilliseconds : self.currentPositionInMilliseconds;
            
            [self trackEvent:endEvent
                  atPosition:endPosition
                  withLabels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                     segment:segment];
            [self trackEvent:SRGAnalyticsPlayerEventPlay
                  atPosition:self.currentPositionInMilliseconds
                  withLabels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                     segment:nil];
        }
        else {
            [self trackEvent:SRGAnalyticsPlayerEventStop
                  atPosition:lastPositionInMilliseconds
                  withLabels:self.mediaPlayerController.userInfo[SRGAnalyticsMediaPlayerLabelsKey]
                     segment:segment];
        }
    }
}

#pragma mark Timers

- (void)heartbeat:(NSTimer *)timer
{
    if (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
        [self trackEvent:SRGAnalyticsPlayerEventHeartbeat atPosition:self.currentPositionInMilliseconds withLabels:self.recentLabels segment:self.recentSegment];
        
        // Send a live hearbeat each minute
        if (self.mediaPlayerController.live && self.heartbeatCount % 2 == 0) {
            [self trackEvent:SRGAnalyticsPlayerEventLiveHeartbeat atPosition:self.currentPositionInMilliseconds withLabels:self.recentLabels segment:self.recentSegment];
        }
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
