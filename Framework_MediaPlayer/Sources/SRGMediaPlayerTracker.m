//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerTracker.h"

#import "NSBundle+SRGAnalytics.h"
#import "NSMutableDictionary+SRGAnalytics.h"
#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsSegment.h"
#import "SRGAnalyticsTracker+Private.h"
#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

NSString * const SRGAnalyticsMediaPlayerLabelsKey = @"SRGAnalyticsMediaPlayerLabels";

static long SRGMediaPlayerTrackerCMTimeToMilliseconds(CMTime time)
{
    return (long)fmax(floor(CMTimeGetSeconds(time) * 1000.), 0.);
}

static long SRGMediaPlayerTrackerCurrentPositionInMilliseconds(SRGMediaPlayerController *mediaPlayerController)
{
    CMTime currentTime = [mediaPlayerController.player.currentItem currentTime];
    if (CMTIME_IS_INDEFINITE(currentTime) || CMTIME_IS_INVALID(currentTime)) {
        return 0;
    }
    else {
        return SRGMediaPlayerTrackerCMTimeToMilliseconds(currentTime);
    }
}

static BOOL SRGMediaPlayerIsLiveStreamType(SRGMediaPlayerStreamType streamType)
{
    return streamType == SRGMediaPlayerStreamTypeLive || streamType == SRGMediaPlayerStreamTypeDVR;
}

static NSNumber *SRGMediaPlayerTimeshiftInMilliseconds(SRGMediaPlayerStreamType streamType, CMTimeRange timeRange, CMTime time, NSTimeInterval liveTolerance)
{
    // Do not return any value for non-live streams
    if (streamType == SRGMediaPlayerStreamTypeDVR) {
        CMTime timeShift = CMTimeSubtract(CMTimeRangeGetEnd(timeRange), time);
        NSInteger timeShiftInSeconds = (NSInteger)fabs(CMTimeGetSeconds(timeShift));
        
        // Consider offsets smaller than the tolerance to be equivalent to live conditions, sending 0 instead of the real offset
        if (timeShiftInSeconds <= liveTolerance) {
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

static NSNumber *SRGMediaPlayerCurrentTimeshiftInMilliseconds(SRGMediaPlayerController *mediaPlayerController)
{
    return SRGMediaPlayerTimeshiftInMilliseconds(mediaPlayerController.streamType,
                                                 mediaPlayerController.timeRange,
                                                 mediaPlayerController.currentTime,
                                                 mediaPlayerController.liveTolerance);
}

static NSMutableDictionary *s_trackers = nil;

@interface SRGMediaPlayerTracker () {
@private
    BOOL _enabled;
}

@property (nonatomic, weak) SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic) NSTimeInterval playbackDuration;
@property (nonatomic) NSDate *previousPlaybackDurationUpdateDate;

@property (nonatomic) NSTimer *heartbeatTimer;
@property (nonatomic) NSUInteger heartbeatCount;

@property (nonatomic) NSString *lastEventUid;

@end

@implementation SRGMediaPlayerTracker

#pragma mark Object lifecycle

- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (self = [super init]) {
        self.mediaPlayerController = mediaPlayerController;
        self.lastEventUid = @"stop";
        
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
        
#if 0
        @weakify(self)
        [mediaPlayerController addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, tracked) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            
            [self updateWithPlaybackState:self.mediaPlayerController.playbackState
                                 position:[self currentPositionInMilliseconds]
                                  segment:self.mediaPlayerController.selectedSegment
                                 userInfo:nil];
        }];
#endif
    }
    return self;
}

- (void)dealloc
{
    self.heartbeatTimer = nil;      // Invalidate timer
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithMediaPlayerController:nil];
}

#pragma clang diagnostic pop

#pragma mark Getters and setters

- (void)setHeartbeatTimer:(NSTimer *)heartbeatTimer
{
    [_heartbeatTimer invalidate];
    _heartbeatTimer = heartbeatTimer;
}

#pragma mark Tracking

- (void)trackMediaPlayerEventWithUid:(NSString *)eventUid
                          streamType:(SRGMediaPlayerStreamType)streamType
                            position:(NSTimeInterval)position
                           timeshift:(NSNumber *)timeshift
                             segment:(id<SRGSegment>)segment
                            userInfo:(NSDictionary *)userInfo
{
    NSAssert(eventUid.length != 0, @"An event uid is required");
    
    if (! [eventUid isEqualToString:@"pos"] && ! [eventUid isEqualToString:@"uptime"]) {
        static dispatch_once_t s_onceToken;
        static NSDictionary<NSString *, NSArray<NSString *> *> *s_transitions;
        dispatch_once(&s_onceToken, ^{
            s_transitions = @{ @"play" : @[ @"pause", @"seek", @"stop", @"eof" ],
                               @"pause" : @[ @"play", @"seek", @"stop", @"eof" ],
                               @"seek" : @[ @"play", @"pause", @"stop", @"eof" ],
                               @"stop" : @[ @"play" ],
                               @"eof" : @[ @"play" ] };
        });
        
        if (! [s_transitions[self.lastEventUid] containsObject:eventUid]) {
            return;
        }
        
        self.lastEventUid = eventUid;
    }
    
    // Restore the heartbeat timer when transitioning to play again.
    if ([eventUid isEqualToString:@"play"]) {
        if (! self.heartbeatTimer) {
            SRGAnalyticsConfiguration *configuration = SRGAnalyticsTracker.sharedTracker.configuration;
            NSTimeInterval heartbeatInterval = configuration.unitTesting ? 3. : 30.;
            self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:heartbeatInterval
                                                                   target:self
                                                                 selector:@selector(heartbeat:)
                                                                 userInfo:nil
                                                                  repeats:YES];
            self.heartbeatCount = 0;
        }
    }
    // Remove the heartbeat when not playing
    else {
        self.heartbeatTimer = nil;
    }
    
    NSMutableDictionary<NSString *, NSString *> *labels = [NSMutableDictionary dictionary];
    
    [labels srg_safelySetString:NSBundle.srg_isProductionVersion ? @"prod" : @"preprod" forKey:@"media_embedding_environment"];
    
    [labels srg_safelySetString:@"SRGMediaPlayer" forKey:@"media_player_display"];
    [labels srg_safelySetString:SRGMediaPlayerMarketingVersion() forKey:@"media_player_version"];
    
    [labels srg_safelySetString:eventUid forKey:@"event_id"];
    
    // Use current duration as media position for livestreams, raw position otherwise
    NSTimeInterval mediaPosition = SRGMediaPlayerIsLiveStreamType(streamType) ? [self updatedPlaybackDurationWithEventUid:eventUid] : position;
    [labels srg_safelySetString:@(round(mediaPosition / 1000)).stringValue forKey:@"media_position"];
    
    [labels srg_safelySetString:self.playerVolumeInPercent.stringValue ?: @"0" forKey:@"media_volume"];
    [labels srg_safelySetString:self.subtitlesEnabled ? @"true" : @"false" forKey:@"media_subtitles_on"];
    
    [labels srg_safelySetString:self.bandwidthInBitsPerSecond.stringValue forKey:@"media_bandwidth"];
    
    if (timeshift) {
        [labels srg_safelySetString:@(timeshift.integerValue / 1000).stringValue forKey:@"media_timeshift"];
    }
    
    // TODO: - Check memory profile
    //       - String enum for event uids (rename eventUid as well)
    
    NSDictionary<NSString *, NSString *> *mainLabels = userInfo[SRGAnalyticsMediaPlayerLabelsKey];
    if (mainLabels) {
        [labels addEntriesFromDictionary:mainLabels];
    }
    
    if ([segment conformsToProtocol:@protocol(SRGAnalyticsSegment)]) {
        NSDictionary<NSString *, NSString *> *segmentLabels = [(id<SRGAnalyticsSegment>)segment srg_analyticsLabels];
        [labels addEntriesFromDictionary:segmentLabels];
    }
    
    [SRGAnalyticsTracker.sharedTracker trackTagCommanderEventWithLabels:[labels copy]];
}

- (NSTimeInterval)updatedPlaybackDurationWithEventUid:(NSString *)eventUid
{
    if (self.previousPlaybackDurationUpdateDate) {
        self.playbackDuration -= [self.previousPlaybackDurationUpdateDate timeIntervalSinceNow] * 1000.;
    }
    
    if ([eventUid isEqualToString:@"play"]) {
        self.previousPlaybackDurationUpdateDate = NSDate.date;
    }
    else {
        self.previousPlaybackDurationUpdateDate = nil;
    }
    
    NSTimeInterval playbackDuration = self.playbackDuration;
    
    if ([eventUid isEqualToString:@"stop"] || [eventUid isEqualToString:@"eof"]) {
        self.playbackDuration = 0;
    }
    
    return playbackDuration;
}

#pragma mark Playback information

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
    CGRect screenRect = UIScreen.mainScreen.bounds;
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
    return s_orientations[@(UIDevice.currentDevice.orientation)];
}

- (NSString *)dimensions
{
    CGSize size = self.mediaPlayerController.playerLayer.videoRect.size;
    return [NSString stringWithFormat:@"%0.fx%0.f", size.width, size.height];
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

- (BOOL)subtitlesEnabled
{
    AVPlayerItem *playerItem = self.mediaPlayerController.player.currentItem;
    AVMediaSelectionGroup *legibleGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelectionOption *currentLegibleOption = [playerItem selectedMediaOptionInMediaSelectionGroup:legibleGroup];
    return currentLegibleOption != nil;
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
    
    if (playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        SRGMediaPlayerTracker *tracker = [[SRGMediaPlayerTracker alloc] initWithMediaPlayerController:mediaPlayerController];
        s_trackers[key] = tracker;
        
        SRGAnalyticsLogInfo(@"PlayerTracker", @"Started tracking for %@", key);
    }
    else if (playbackState == SRGMediaPlayerPlaybackStateIdle) {
        SRGMediaPlayerTracker *tracker = s_trackers[key];
        if (tracker) {
            if (previousPlaybackState != SRGMediaPlayerPlaybackStatePreparing) {
                SRGMediaPlayerStreamType streamType = [notification.userInfo[SRGMediaPlayerPreviousStreamTypeKey] integerValue];
                NSTimeInterval position = SRGMediaPlayerTrackerCMTimeToMilliseconds([notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue]);
                NSNumber *timeshift = SRGMediaPlayerTimeshiftInMilliseconds(streamType,
                                                                            [notification.userInfo[SRGMediaPlayerPreviousTimeRangeKey] CMTimeRangeValue],
                                                                            [notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue],
                                                                            mediaPlayerController.liveTolerance);
                [tracker trackMediaPlayerEventWithUid:@"stop"
                                           streamType:streamType
                                             position:position
                                            timeshift:timeshift
                                              segment:notification.userInfo[SRGMediaPlayerPreviousSelectedSegmentKey]
                                             userInfo:notification.userInfo[SRGMediaPlayerPreviousUserInfoKey]];
            }
            s_trackers[key] = nil;
            
            SRGAnalyticsLogInfo(@"PlayerTracker", @"Stopped tracking for %@", key);
        }
    }
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerController *mediaPlayerController = notification.object;
    
    SRGMediaPlayerPlaybackState playbackState = mediaPlayerController.playbackState;
    if (playbackState == SRGMediaPlayerPlaybackStateIdle || playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        return;
    }
    
    // Inhibit usual playback transitions occuring during segment selection
    if ([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]) {
        return;
    }
    
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_eventUids;
    dispatch_once(&s_onceToken, ^{
        s_eventUids = @{ @(SRGMediaPlayerPlaybackStateIdle) : @"stop",
                         @(SRGMediaPlayerPlaybackStatePlaying) : @"play",
                         @(SRGMediaPlayerPlaybackStateSeeking) : @"seek",
                         @(SRGMediaPlayerPlaybackStatePaused) : @"pause",
                         @(SRGMediaPlayerPlaybackStateEnded) : @"eof" };
    });
    
    NSString *eventUid = s_eventUids[@(playbackState)];
    if (! eventUid) {
        return;
    }
    
    [self trackMediaPlayerEventWithUid:eventUid
                            streamType:mediaPlayerController.streamType
                              position:SRGMediaPlayerTrackerCurrentPositionInMilliseconds(mediaPlayerController)
                             timeshift:SRGMediaPlayerCurrentTimeshiftInMilliseconds(mediaPlayerController)
                               segment:mediaPlayerController.selectedSegment
                              userInfo:mediaPlayerController.userInfo];
}

- (void)segmentDidStart:(NSNotification *)notification
{
    // Only send analytics for segment selections
    if ([notification.userInfo[SRGMediaPlayerSelectionKey] boolValue]) {
        SRGMediaPlayerController *mediaPlayerController = notification.object;
        SRGMediaPlayerStreamType streamType = mediaPlayerController.streamType;
        
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        
        // Notify full-length end (only if not starting at the given segment, i.e. if the player is not preparing playback)
        id<SRGSegment> previousSegment = notification.userInfo[SRGMediaPlayerPreviousSegmentKey];
        if (! previousSegment && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePreparing) {
            CMTime lastPlaybackTime = [notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue];
            NSTimeInterval position = SRGMediaPlayerTrackerCMTimeToMilliseconds(lastPlaybackTime);
            NSNumber *timeshift = SRGMediaPlayerTimeshiftInMilliseconds(streamType, mediaPlayerController.timeRange, lastPlaybackTime, mediaPlayerController.liveTolerance);
            
            [self trackMediaPlayerEventWithUid:@"stop"
                                    streamType:streamType
                                      position:position
                                     timeshift:timeshift
                                       segment:nil
                                      userInfo:mediaPlayerController.userInfo];
        }
        
        [self trackMediaPlayerEventWithUid:@"play"
                                streamType:streamType
                                  position:SRGMediaPlayerTrackerCurrentPositionInMilliseconds(mediaPlayerController)
                                 timeshift:SRGMediaPlayerCurrentTimeshiftInMilliseconds(mediaPlayerController)
                                   segment:segment
                                  userInfo:mediaPlayerController.userInfo];
    }
}

- (void)segmentDidEnd:(NSNotification *)notification
{
    // Only send analytics for segments which were selected
    if ([notification.userInfo[SRGMediaPlayerSelectedKey] boolValue]) {
        SRGMediaPlayerController *mediaPlayerController = notification.object;
        SRGMediaPlayerStreamType streamType = mediaPlayerController.streamType;
        
        id<SRGSegment> segment = notification.userInfo[SRGMediaPlayerSegmentKey];
        
        CMTime lastPlaybackTime = [notification.userInfo[SRGMediaPlayerLastPlaybackTimeKey] CMTimeValue];
        NSTimeInterval lastPosition = SRGMediaPlayerTrackerCMTimeToMilliseconds(lastPlaybackTime);
        NSNumber *lastTimeshift = SRGMediaPlayerTimeshiftInMilliseconds(streamType, mediaPlayerController.timeRange, lastPlaybackTime, mediaPlayerController.liveTolerance);
        
        // Notify full-length start if the transition was not due to another segment being selected
        if (! [notification.userInfo[SRGMediaPlayerSelectionKey] boolValue] && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded) {
            BOOL interrupted = [notification.userInfo[SRGMediaPlayerInterruptionKey] boolValue];
            [self trackMediaPlayerEventWithUid:interrupted ? @"stop" : @"eof"
                                    streamType:streamType
                                      position:lastPosition
                                     timeshift:lastTimeshift
                                       segment:segment
                                      userInfo:mediaPlayerController.userInfo];
            [self trackMediaPlayerEventWithUid:@"play"
                                    streamType:streamType
                                      position:SRGMediaPlayerTrackerCurrentPositionInMilliseconds(mediaPlayerController)
                                     timeshift:SRGMediaPlayerCurrentTimeshiftInMilliseconds(mediaPlayerController)
                                       segment:nil
                                      userInfo:mediaPlayerController.userInfo];
        }
        else {
            [self trackMediaPlayerEventWithUid:@"stop"
                                    streamType:streamType
                                      position:lastPosition
                                     timeshift:lastTimeshift
                                       segment:segment
                                      userInfo:mediaPlayerController.userInfo];
        }
    }
}

#pragma mark Timers

- (void)heartbeat:(NSTimer *)timer
{
    SRGMediaPlayerStreamType streamType = self.mediaPlayerController.streamType;
    NSTimeInterval position = SRGMediaPlayerTrackerCurrentPositionInMilliseconds(self.mediaPlayerController);
    NSNumber *timeshift = SRGMediaPlayerCurrentTimeshiftInMilliseconds(self.mediaPlayerController);
    
    [self trackMediaPlayerEventWithUid:@"pos"
                            streamType:streamType
                              position:position
                             timeshift:timeshift
                               segment:self.mediaPlayerController.selectedSegment
                              userInfo:self.mediaPlayerController.userInfo];
    
    // Send a live heartbeat each minute
    if (self.mediaPlayerController.live && self.heartbeatCount % 2 != 0) {
        [self trackMediaPlayerEventWithUid:@"uptime"
                                streamType:streamType
                                  position:position
                                 timeshift:timeshift
                                   segment:self.mediaPlayerController.selectedSegment
                                  userInfo:self.mediaPlayerController.userInfo];
    }
    
    self.heartbeatCount += 1;
}

@end

#pragma mark Static functions

__attribute__((constructor)) static void SRGMediaPlayerTrackerInit(void)
{
    // Observe state changes for all media player controllers to create and remove trackers on the fly
    [NSNotificationCenter.defaultCenter addObserver:SRGMediaPlayerTracker.class
                                           selector:@selector(playbackStateDidChange:)
                                               name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                             object:nil];
    
    s_trackers = [NSMutableDictionary dictionary];
}
