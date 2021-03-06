//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsStreamTracker.h"

#import "NSMutableDictionary+SRGAnalytics.h"
#import "SRGAnalyticsTracker+Private.h"

#import <ComScore/ComScore.h>
#import <SRGAnalytics/SRGAnalytics.h>

@interface SRGAnalyticsStreamTracker ()

@property (nonatomic, getter=isLivestream) BOOL livestream;

@property (nonatomic) CSStreamSense *streamSense;

@property (nonatomic, getter=isComScoreSessionAlive) BOOL comScoreSessionAlive;
@property (nonatomic) SRGAnalyticsStreamState previousPlayerState;

@property (nonatomic) NSTimeInterval playbackDuration;
@property (nonatomic) NSDate *previousPlaybackDurationUpdateDate;

@property (nonatomic) NSTimer *heartbeatTimer;
@property (nonatomic) NSUInteger heartbeatCount;

@end

@implementation SRGAnalyticsStreamTracker

#pragma mark Object lifecycle

- (instancetype)initForLivestream:(BOOL)livestream
{
    if (self = [super init]) {
        self.livestream = livestream;
        
        // The default keep-alive time interval of 20 minutes is too big. Set it to 9 minutes
        self.streamSense = [[CSStreamSense alloc] init];
        [self.streamSense setKeepAliveInterval:9 * 60];
        
        self.previousPlayerState = SRGAnalyticsStreamStateEnded;
    }
    return self;
}

- (instancetype)init
{
    return [self initForLivestream:NO];
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

#pragma mark Tracking

- (void)updateWithStreamState:(SRGAnalyticsStreamState)state
                     position:(NSTimeInterval)position
                       labels:(SRGAnalyticsStreamLabels *)labels
{
    [self updateTagCommanderWithStreamState:state position:position labels:labels];
    [self updateComScoreWithStreamState:state position:position labels:labels];
}

- (void)updateComScoreWithStreamState:(SRGAnalyticsStreamState)state
                             position:(NSTimeInterval)position
                               labels:(SRGAnalyticsStreamLabels *)labels
{
    // Ensure a play is emitted before events requiring a session to be opened (the comScore SDK does not open sessions
    // automatically)
    if (! self.comScoreSessionAlive && (state == SRGAnalyticsStreamStatePaused || state == SRGAnalyticsStreamStateSeeking)) {
        [self updateComScoreWithStreamState:SRGAnalyticsStreamStatePlaying position:position labels:labels];
    }
    
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSNumber *> *s_streamSenseEvents;
    dispatch_once(&s_onceToken, ^{
        s_streamSenseEvents = @{ @(SRGAnalyticsStreamStatePlaying) : @(CSStreamSensePlay),
                                 @(SRGAnalyticsStreamStatePaused) : @(CSStreamSensePause),
                                 @(SRGAnalyticsStreamStateSeeking) : @(CSStreamSensePause),
                                 @(SRGAnalyticsStreamStateStopped) : @(CSStreamSenseEnd),
                                 @(SRGAnalyticsStreamStateEnded) : @(CSStreamSenseEnd) };
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

- (void)updateTagCommanderWithStreamState:(SRGAnalyticsStreamState)state
                                 position:(NSTimeInterval)position
                                   labels:(SRGAnalyticsStreamLabels *)labels
{
    // Ensure a play is emitted before events requiring a session to be opened (the TagCommander SDK does not open sessions
    // automatically)
    if (self.previousPlayerState == SRGAnalyticsStreamStateEnded && (state == SRGAnalyticsStreamStatePaused || state == SRGAnalyticsStreamStateSeeking)) {
        [self updateTagCommanderWithStreamState:SRGAnalyticsStreamStatePlaying position:position labels:labels];
    }
    
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_eventUids;
    static NSDictionary<NSNumber *, NSArray<NSNumber *> *> *s_transitions;
    dispatch_once(&s_onceToken, ^{
        s_eventUids = @{ @(SRGAnalyticsStreamStatePlaying) : @"play",
                         @(SRGAnalyticsStreamStatePaused) : @"pause",
                         @(SRGAnalyticsStreamStateSeeking) : @"seek",
                         @(SRGAnalyticsStreamStateStopped) : @"stop",
                         @(SRGAnalyticsStreamStateEnded) : @"eof" };
        s_transitions = @{ @(SRGAnalyticsStreamStatePlaying) : @[ @(SRGAnalyticsStreamStatePaused), @(SRGAnalyticsStreamStateSeeking), @(SRGAnalyticsStreamStateStopped), @(SRGAnalyticsStreamStateEnded) ],
                           @(SRGAnalyticsStreamStatePaused) : @[ @(SRGAnalyticsStreamStatePlaying), @(SRGAnalyticsStreamStateSeeking), @(SRGAnalyticsStreamStateStopped), @(SRGAnalyticsStreamStateEnded) ],
                           @(SRGAnalyticsStreamStateSeeking) : @[ @(SRGAnalyticsStreamStatePlaying), @(SRGAnalyticsStreamStatePaused), @(SRGAnalyticsStreamStateStopped), @(SRGAnalyticsStreamStateEnded) ],
                           @(SRGAnalyticsStreamStateStopped) : @[ @(SRGAnalyticsStreamStatePlaying) ],
                           @(SRGAnalyticsStreamStateEnded) : @[ @(SRGAnalyticsStreamStatePlaying) ] };
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
    
    // Restore the heartbeat timer when transitioning to play again.
    if (state == SRGAnalyticsStreamStatePlaying) {
        if (! self.heartbeatTimer) {
            SRGAnalyticsConfiguration *configuration = SRGAnalyticsTracker.sharedTracker.configuration;
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

- (void)trackTagCommanderMediaPlayerEventWithUid:(NSString *)eventUid withPosition:(NSTimeInterval)position labels:(SRGAnalyticsStreamLabels *)labels
{
    NSAssert(eventUid.length != 0, @"An event uid is required");
    
    NSMutableDictionary<NSString *, NSString *> *fullLabelsDictionary = [NSMutableDictionary dictionary];
    [fullLabelsDictionary srg_safelySetString:eventUid forKey:@"event_id"];
    [fullLabelsDictionary srg_safelySetString:@(round(position / 1000)).stringValue forKey:@"media_position"];
    
    NSDictionary<NSString *, NSString *> *labelsDictionary = [labels labelsDictionary];
    if (labelsDictionary) {
        [fullLabelsDictionary addEntriesFromDictionary:labelsDictionary];
    }
    
    [SRGAnalyticsTracker.sharedTracker trackTagCommanderEventWithLabels:[fullLabelsDictionary copy]];
}

#pragma mark Playback duration

- (NSTimeInterval)updatedPlaybackDurationWithState:(SRGAnalyticsStreamState)state
{
    NSAssert(self.livestream, @"Duration calculated for livestreams only");
    
    if (self.previousPlaybackDurationUpdateDate) {
        self.playbackDuration -= [self.previousPlaybackDurationUpdateDate timeIntervalSinceNow] * 1000;
    }
    
    if (state == SRGAnalyticsStreamStatePlaying) {
        self.previousPlaybackDurationUpdateDate = NSDate.date;
    }
    else {
        self.previousPlaybackDurationUpdateDate = nil;
    }
    
    NSTimeInterval playbackDuration = self.playbackDuration;
    
    if (state == SRGAnalyticsStreamStateStopped || state == SRGAnalyticsStreamStateEnded) {
        self.playbackDuration = 0;
    }
    
    return playbackDuration;
}

#pragma mark Timers

- (void)heartbeat:(NSTimer *)timer
{
    NSAssert(self.previousPlayerState == SRGAnalyticsStreamStatePlaying, @"Heartbeat timer is only active when playing by construction");
    
    if (self.delegate) {
        NSTimeInterval position = [self.delegate positionForStreamTracker:self];
        
        // Override position if it is a livestream
        if (self.livestream) {
            position = [self updatedPlaybackDurationWithState:SRGAnalyticsStreamStatePlaying];
        }
        
        SRGAnalyticsStreamLabels *labels = [self.delegate labelsForStreamTracker:self];
        [self trackTagCommanderMediaPlayerEventWithUid:@"pos" withPosition:position labels:labels];
        
        // Send a live heartbeat each minute
        if ([self.delegate streamTrackerIsPlayingLive:self] && self.heartbeatCount % 2 != 0) {
            [self trackTagCommanderMediaPlayerEventWithUid:@"uptime" withPosition:position labels:labels];
        }
    }
    
    self.heartbeatCount += 1;
}

@end
