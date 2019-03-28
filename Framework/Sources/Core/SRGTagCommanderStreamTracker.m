//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGTagCommanderStreamTracker.h"

#import "NSMutableDictionary+SRGAnalytics.h"
#import "SRGAnalyticsTracker+Private.h"

@interface SRGTagCommanderStreamTracker ()

@property (nonatomic) SRGAnalyticsStreamType streamType;
@property (nonatomic, weak) id<SRGAnalyticsStreamTrackerDelegate> delegate;

@property (nonatomic) NSTimeInterval playbackDuration;
@property (nonatomic) NSDate *previousPlaybackDurationUpdateDate;

@property (nonatomic) NSTimer *heartbeatTimer;
@property (nonatomic) NSUInteger heartbeatCount;

@property (nonatomic) SRGAnalyticsStreamState state;

@end

@implementation SRGTagCommanderStreamTracker

#pragma mark Object lifecycle

- (instancetype)initWithStreamType:(SRGAnalyticsStreamType)streamType delegate:(id<SRGAnalyticsStreamTrackerDelegate>)delegate
{
    if (self = [super init]) {
        self.streamType = streamType;
        self.delegate = delegate;
        self.state = SRGAnalyticsStreamStateEnded;
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

- (BOOL)isLivestream
{
    return (self.streamType == SRGAnalyticsStreamTypeLive || self.streamType == SRGAnalyticsStreamTypeDVR);
}

#pragma mark Tracking

- (void)updateWithStreamState:(SRGAnalyticsStreamState)state position:(NSTimeInterval)position labels:(SRGAnalyticsStreamLabels *)labels
{
    // Ensure a play is emitted before events requiring a session to be opened (the TagCommander SDK does not open sessions
    // automatically)
    if (self.state == SRGAnalyticsStreamStateEnded && (state == SRGAnalyticsStreamStatePaused || state == SRGAnalyticsStreamStateSeeking)) {
        [self updateWithStreamState:SRGAnalyticsStreamStatePlaying position:position labels:labels];
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
    if (! [s_transitions[@(self.state)] containsObject:@(state)]) {
        return;
    }
    
    self.state = state;
    
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
    if ([self isLivestream]) {
        [self trackMediaPlayerEventWithUid:action withPosition:[self updatedPlaybackDurationWithState:state] labels:labels];
    }
    else {
        [self trackMediaPlayerEventWithUid:action withPosition:position labels:labels];
    }
}

- (void)trackMediaPlayerEventWithUid:(NSString *)eventUid withPosition:(NSTimeInterval)position labels:(SRGAnalyticsStreamLabels *)labels
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
    NSAssert([self isLivestream], @"Duration calculated for livestreams only");
    
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
    NSAssert(self.state == SRGAnalyticsStreamStatePlaying, @"Heartbeat timer is only active when playing by construction");
    
    NSTimeInterval position = [self isLivestream] ? [self updatedPlaybackDurationWithState:SRGAnalyticsStreamStatePlaying] : self.delegate.playbackPosition;
    [self trackMediaPlayerEventWithUid:@"pos" withPosition:position labels:self.delegate.labels];
    
    // Send a live heartbeat each minute
    if (self.delegate.live && self.heartbeatCount % 2 != 0) {
        [self trackMediaPlayerEventWithUid:@"uptime" withPosition:position labels:self.delegate.labels];
    }
    
    self.heartbeatCount += 1;
}

@end
