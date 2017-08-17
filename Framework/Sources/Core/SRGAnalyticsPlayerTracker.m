//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsPlayerTracker.h"

#import "NSBundle+SRGAnalytics.h"
#import "NSMutableDictionary+SRGAnalytics.h"
#import "SRGAnalyticsTracker+Private.h"

#import <ComScore/ComScore.h>
#import <SRGAnalytics/SRGAnalytics.h>

@interface SRGAnalyticsPlayerTracker ()

@property (nonatomic) CSStreamSense *streamSense;

@property (nonatomic, getter=isComScoreSessionAlive) BOOL comScoreSessionAlive;
@property (nonatomic) SRGAnalyticsPlayerState previousPlayerState;

@property (nonatomic) NSTimeInterval playbackDuration;
@property (nonatomic) NSDate *previousPlaybackDurationUpdateDate;

@property (nonatomic) NSTimer *heartbeatTimer;
@property (nonatomic) NSUInteger heartbeatCount;

@end

@implementation SRGAnalyticsPlayerLabels

#pragma mark Getters and setters

- (NSDictionary<NSString *, NSString *> *)labelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary srg_safelySetString:[NSBundle srg_isProductionVersion] ? @"prod" : @"preprod" forKey:@"media_embedding_environment"];
    
    [dictionary srg_safelySetString:self.playerName forKey:@"media_player_display"];
    [dictionary srg_safelySetString:self.playerVersion forKey:@"media_player_version"];
    [dictionary srg_safelySetString:self.playerVolumeInPercent.stringValue ?: @"0" forKey:@"media_volume"];
    
    [dictionary srg_safelySetString:self.subtitlesEnabled.boolValue ? @"true" : @"false" forKey:@"media_subtitles_on"];
    [dictionary srg_safelySetString:self.timeshiftInMilliseconds ? @(self.timeshiftInMilliseconds.integerValue / 1000).stringValue : nil forKey:@"media_timeshift"];
    [dictionary srg_safelySetString:self.bandwidthInBitsPerSecond.stringValue forKey:@"media_bandwidth"];
    
    if (self.customInfo) {
        [dictionary addEntriesFromDictionary:self.customInfo];
    }
    
    return [dictionary copy];
}

- (NSDictionary<NSString *, NSString *> *)comScoreLabelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary srg_safelySetString:@"c" forKey:@"ns_st_it"];
    [dictionary srg_safelySetString:@"p_app_ios" forKey:@"srg_ptype"];
    
    [dictionary srg_safelySetString:self.playerName forKey:@"ns_st_mp"];
    [dictionary srg_safelySetString:self.playerVersion forKey:@"ns_st_mv"];
    [dictionary srg_safelySetString:self.playerVolumeInPercent.stringValue ?: @"0" forKey:@"ns_st_vo"];
    
    [dictionary srg_safelySetString:self.bandwidthInBitsPerSecond.stringValue forKey:@"ns_st_br"];
    
    if (self.comScoreCustomInfo) {
        [dictionary addEntriesFromDictionary:self.comScoreCustomInfo];
    }
    
    return [dictionary copy];
}

- (NSDictionary<NSString *, NSString *> *)comScoreSegmentLabelsDictionary
{
    NSMutableDictionary <NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary srg_safelySetString:self.timeshiftInMilliseconds.stringValue forKey:@"srg_timeshift"];
    
    if (self.comScoreCustomSegmentInfo) {
        [dictionary addEntriesFromDictionary:self.comScoreCustomSegmentInfo];
    }
    
    return [dictionary copy];
}

#pragma mark Merging

- (void)mergeWithLabels:(SRGAnalyticsPlayerLabels *)labels
{
    if (! labels) {
        return;
    }
    
    if (labels.playerName) {
        self.playerName = labels.playerName;
    }
    if (labels.playerVersion) {
        self.playerVersion = labels.playerVersion;
    }
    if (labels.playerVolumeInPercent) {
        self.playerVolumeInPercent = labels.playerVolumeInPercent;
    }
    
    if (labels.subtitlesEnabled) {
        self.subtitlesEnabled = labels.subtitlesEnabled;
    }
    if (labels.timeshiftInMilliseconds) {
        self.timeshiftInMilliseconds = labels.timeshiftInMilliseconds;
    }
    if (labels.bandwidthInBitsPerSecond) {
        self.bandwidthInBitsPerSecond = labels.bandwidthInBitsPerSecond;
    }
    
    NSMutableDictionary *customInfo = [self.customInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    if (labels.customInfo) {
        [customInfo addEntriesFromDictionary:labels.customInfo];
    }
    self.customInfo = (customInfo.count != 0) ? [customInfo copy] : nil;
    
    NSMutableDictionary *comScoreCustomInfo = [self.comScoreCustomInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    if (labels.comScoreCustomInfo) {
        [comScoreCustomInfo addEntriesFromDictionary:labels.comScoreCustomInfo];
    }
    self.comScoreCustomInfo = (comScoreCustomInfo.count != 0) ? [comScoreCustomInfo copy] : nil;
    
    NSMutableDictionary *comScoreCustomSegmentInfo = [self.comScoreCustomSegmentInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    if (labels.comScoreCustomSegmentInfo) {
        [comScoreCustomSegmentInfo addEntriesFromDictionary:labels.comScoreCustomSegmentInfo];
    }
    self.comScoreCustomSegmentInfo = (comScoreCustomSegmentInfo.count != 0) ? [comScoreCustomSegmentInfo copy] : nil;
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.playerName = self.playerName;
    labels.playerVersion = self.playerVersion;
    labels.playerVolumeInPercent = self.playerVolumeInPercent;
    labels.subtitlesEnabled = self.subtitlesEnabled;
    labels.timeshiftInMilliseconds = self.timeshiftInMilliseconds;
    labels.bandwidthInBitsPerSecond = self.bandwidthInBitsPerSecond;
    labels.customInfo = self.customInfo;
    labels.comScoreCustomInfo = self.comScoreCustomInfo;
    labels.comScoreCustomSegmentInfo = self.comScoreCustomSegmentInfo;
    return labels;
}

@end

@implementation SRGAnalyticsPlayerTracker

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        // The default keep-alive time interval of 20 minutes is too big. Set it to 9 minutes
        self.streamSense = [[CSStreamSense alloc] init];
        [self.streamSense setKeepAliveInterval:9 * 60];
        
        self.previousPlayerState = SRGAnalyticsPlayerStateEnded;
    }
    return self;
}

- (void)dealloc
{
    self.heartbeatTimer = nil;      // Invalidate timer
}

#pragma mark Getters and setters

- (void)setHeartbeatTimer:(NSTimer *)heartbeatTimer
{
    [_heartbeatTimer invalidate];
    _heartbeatTimer = heartbeatTimer;
    self.heartbeatCount = 0;
}

#pragma mark State updates

- (void)updateWithPlayerState:(SRGAnalyticsPlayerState)state
                     position:(NSTimeInterval)position
                       labels:(SRGAnalyticsPlayerLabels *)labels
{
    [self updateTagCommanderWithPlayerState:state position:position labels:labels];
    [self updateComScoreWithPlayerState:state position:position labels:labels];
}

- (void)updateComScoreWithPlayerState:(SRGAnalyticsPlayerState)state
                             position:(NSTimeInterval)position
                               labels:(SRGAnalyticsPlayerLabels *)labels
{
    // Ensure a play is emitted before events requiring a session to be opened (the comScore SDK does not open sessions
    // automatically)
    if (! self.comScoreSessionAlive && (state == SRGAnalyticsPlayerStatePaused || state == SRGAnalyticsPlayerStateSeeking)) {
        [self updateComScoreWithPlayerState:SRGAnalyticsPlayerStatePlaying position:position labels:labels];
    }
    
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSNumber *> *s_streamSenseEvents;
    dispatch_once(&s_onceToken, ^{
        s_streamSenseEvents = @{ @(SRGAnalyticsPlayerStatePlaying) : @(CSStreamSensePlay),
                                 @(SRGAnalyticsPlayerStatePaused) : @(CSStreamSensePause),
                                 @(SRGAnalyticsPlayerStateSeeking) : @(CSStreamSensePause),
                                 @(SRGAnalyticsPlayerStateStopped) : @(CSStreamSenseEnd),
                                 @(SRGAnalyticsPlayerStateEnded) : @(CSStreamSenseEnd) };
    });
    
    NSNumber *eventTypeValue = s_streamSenseEvents[@(state)];
    if (! eventTypeValue) {
        return;
    }
    
    [[self.streamSense labels] removeAllObjects];
    [[labels comScoreLabelsDictionary] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [self.streamSense setLabel:key value:object];
    }];
    
    // Reset clip labels to avoid inheriting from a previous segment. This does not reset internal hidden comScore labels
    // (e.g. ns_st_pa), which would otherwise be incorrect
    [[[self.streamSense clip] labels] removeAllObjects];
    [[labels comScoreSegmentLabelsDictionary] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [[self.streamSense clip] setLabel:key value:object];
    }];
    
    if (self.livestream) {
        position = 0;
    }
    
    CSStreamSenseEventType eventType = eventTypeValue.intValue;
    [self.streamSense notify:eventType position:position labels:nil /* already set on the stream and clip objects */];
    
    if (eventType == CSStreamSensePlay) {
        self.comScoreSessionAlive = YES;
    }
    else if (eventType == CSStreamSenseEnd) {
        self.comScoreSessionAlive = NO;
    }
}

- (void)updateTagCommanderWithPlayerState:(SRGAnalyticsPlayerState)state
                                 position:(NSTimeInterval)position
                                   labels:(SRGAnalyticsPlayerLabels *)labels
{
    // Ensure a play is emitted before events requiring a session to be opened (the TagCommander SDK does not open sessions
    // automatically)
    if (self.previousPlayerState == SRGAnalyticsPlayerStateEnded && (state == SRGAnalyticsPlayerStatePaused || state == SRGAnalyticsPlayerStateSeeking)) {
        [self updateTagCommanderWithPlayerState:SRGAnalyticsPlayerStatePlaying position:position labels:labels];
    }
    
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_eventUids;
    static NSDictionary<NSNumber *, NSArray<NSNumber *> *> *s_transitions;
    dispatch_once(&s_onceToken, ^{
        s_eventUids = @{ @(SRGAnalyticsPlayerStatePlaying) : @"play",
                         @(SRGAnalyticsPlayerStatePaused) : @"pause",
                         @(SRGAnalyticsPlayerStateSeeking) : @"seek",
                         @(SRGAnalyticsPlayerStateStopped) : @"stop",
                         @(SRGAnalyticsPlayerStateEnded) : @"eof" };
        s_transitions = @{ @(SRGAnalyticsPlayerStatePlaying) : @[ @(SRGAnalyticsPlayerStatePaused), @(SRGAnalyticsPlayerStateSeeking), @(SRGAnalyticsPlayerStateStopped), @(SRGAnalyticsPlayerStateEnded) ],
                           @(SRGAnalyticsPlayerStatePaused) : @[ @(SRGAnalyticsPlayerStatePlaying), @(SRGAnalyticsPlayerStateSeeking), @(SRGAnalyticsPlayerStateStopped), @(SRGAnalyticsPlayerStateEnded) ],
                           @(SRGAnalyticsPlayerStateSeeking) : @[ @(SRGAnalyticsPlayerStatePlaying), @(SRGAnalyticsPlayerStatePaused), @(SRGAnalyticsPlayerStateStopped), @(SRGAnalyticsPlayerStateEnded) ],
                           @(SRGAnalyticsPlayerStateStopped) : @[ @(SRGAnalyticsPlayerStatePlaying) ],
                           @(SRGAnalyticsPlayerStateEnded) : @[ @(SRGAnalyticsPlayerStatePlaying) ] };
    });
    
    // Don't send an unknown action
    NSString *action = s_eventUids[@(state)];
    if (! action) {
        return;
    }
    
    // Don't send an unallowed action
    if (! [s_transitions[@(self.previousPlayerState)] containsObject:@(state)]) {
        return;
    }
    
    self.previousPlayerState = state;
    
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
    else {
        self.heartbeatTimer = nil;
    }
    
    // Override position if it is a livestream
    if (self.livestream) {
        position = [self updatedPlaybackDurationWithState:state];
    }
    
    // Send the event
    [self trackTagCommanderMediaPlayerEventWithUid:action withPosition:position labels:labels];
}

- (void)trackTagCommanderMediaPlayerEventWithUid:(NSString *)eventUid withPosition:(NSTimeInterval)position labels:(SRGAnalyticsPlayerLabels *)labels
{
    NSAssert(eventUid.length != 0, @"An event uid is required");
    
    NSMutableDictionary<NSString *, NSString *> *fullLabelsDictionary = [NSMutableDictionary dictionary];
    [fullLabelsDictionary srg_safelySetString:eventUid forKey:@"event_id"];
    [fullLabelsDictionary srg_safelySetString:@(round(position / 1000)).stringValue forKey:@"media_position"];
    
    NSDictionary<NSString *, NSString *> *labelsDictionary = [labels labelsDictionary];
    if (labelsDictionary) {
        [fullLabelsDictionary addEntriesFromDictionary:labelsDictionary];
    }
    
    [[SRGAnalyticsTracker sharedTracker] trackTagCommanderEventWithLabels:[fullLabelsDictionary copy]];
}

#pragma mark Playback duration

- (NSTimeInterval)updatedPlaybackDurationWithState:(SRGAnalyticsPlayerState)state
{
    NSAssert(self.livestream, @"Duration calculated for livestreams only");
    
    if (self.previousPlaybackDurationUpdateDate) {
        self.playbackDuration += fabs([self.previousPlaybackDurationUpdateDate timeIntervalSinceNow] * 1000);
    }
    
    if (state == SRGAnalyticsPlayerStatePlaying) {
        self.previousPlaybackDurationUpdateDate = NSDate.date;
    }
    else {
        self.previousPlaybackDurationUpdateDate = nil;
    }
    
    NSTimeInterval playbackDuration = self.playbackDuration;
    
    if (state == SRGAnalyticsPlayerStateStopped || state == SRGAnalyticsPlayerStateEnded) {
        self.playbackDuration = 0;
    }
    
    return playbackDuration;
}

#pragma mark Timers

- (void)heartbeat:(NSTimer *)timer
{
    NSAssert(self.previousPlayerState == SRGAnalyticsPlayerStatePlaying, @"Heartbeat timer is only active when playing by construction");
    
    if (self.delegate) {
        NSTimeInterval position = [self.delegate positionForPlayerTracker:self];
        
        // Override position if it is a livestream
        if (self.livestream) {
            position = [self updatedPlaybackDurationWithState:SRGAnalyticsPlayerStatePlaying];
        }
        
        SRGAnalyticsPlayerLabels *labels = [self.delegate labelsForPlayerTracker:self];
        [self trackTagCommanderMediaPlayerEventWithUid:@"pos" withPosition:position labels:labels];
        
        // Send a live heartbeat each minute
        if ([self.delegate playerTrackerIsLive:self] && self.heartbeatCount % 2 != 0) {
            [self trackTagCommanderMediaPlayerEventWithUid:@"uptime" withPosition:position labels:labels];
        }
    }
    
    self.heartbeatCount += 1;
}

@end
