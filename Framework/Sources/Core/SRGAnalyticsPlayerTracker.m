//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsPlayerTracker.h"

#import "NSMutableDictionary+SRGAnalytics.h"
#import "SRGAnalyticsTracker+Private.h"

#import <ComScore/ComScore.h>

@interface SRGAnalyticsPlayerTracker ()

@property (nonatomic) CSStreamSense *streamSense;

@property (nonatomic) SRGAnalyticsPlayerEvent previousPlayerEvent;

@end

@implementation SRGAnalyticsPlayerTracker

- (instancetype)init
{
    if (self = [super init]) {
        // The default keep-alive time interval of 20 minutes is too big. Set it to 9 minutes
        self.streamSense = [[CSStreamSense alloc] init];
        [self.streamSense setKeepAliveInterval:9 * 60];
        
        self.previousPlayerEvent = SRGAnalyticsPlayerEventEnd;
    }
    return self;
}

- (void)trackPlayerEvent:(SRGAnalyticsPlayerEvent)event
              atPosition:(NSTimeInterval)position
              withLabels:(NSDictionary<NSString *, NSString *> *)labels
          comScoreLabels:(NSDictionary<NSString *, NSString *> *)comScoreLabels
   comScoreSegmentLabels:(NSDictionary<NSString *, NSString *> *)comScoreSegmentLabels
{
    [self trackTagCommanderPlayerEvent:event atPosition:position withLabels:labels];
    [self trackComScorePlayerEvent:event atPosition:position withLabels:comScoreLabels segmentLabels:comScoreSegmentLabels];
}

- (void)trackComScorePlayerEvent:(SRGAnalyticsPlayerEvent)event
                      atPosition:(NSTimeInterval)position
                      withLabels:(NSDictionary<NSString *, NSString *> *)labels
                   segmentLabels:(NSDictionary<NSString *, NSString *> *)segmentLabels
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSNumber *> *s_streamSenseEvents;
    dispatch_once(&s_onceToken, ^{
        s_streamSenseEvents = @{ @(SRGAnalyticsPlayerEventBuffer) : @(CSStreamSenseBuffer),
                                 @(SRGAnalyticsPlayerEventPlay) : @(CSStreamSensePlay),
                                 @(SRGAnalyticsPlayerEventPause) : @(CSStreamSensePause),
                                 @(SRGAnalyticsPlayerEventSeek) : @(CSStreamSensePause),
                                 @(SRGAnalyticsPlayerEventStop) : @(CSStreamSenseEnd),
                                 @(SRGAnalyticsPlayerEventEnd) : @(CSStreamSenseEnd) };
    });
    
    NSNumber *eventType = s_streamSenseEvents[@(event)];
    if (! eventType) {
        return;
    }
    
    [[self.streamSense labels] removeAllObjects];
    [labels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [self.streamSense setLabel:key value:object];
    }];
    
    // Reset clip labels to avoid inheriting from a previous segment. This does not reset internal hidden comScore labels
    // (e.g. ns_st_pa), which would otherwise be incorrect
    [[[self.streamSense clip] labels] removeAllObjects];
    [segmentLabels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [[self.streamSense clip] setLabel:key value:object];
    }];
    
    [self.streamSense notify:eventType.intValue position:position labels:nil /* already set on the stream and clip objects */];
}

- (void)trackTagCommanderPlayerEvent:(SRGAnalyticsPlayerEvent)event
                          atPosition:(NSTimeInterval)position
                          withLabels:(NSDictionary<NSString *,NSString *> *)labels
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_actions;
    dispatch_once(&s_onceToken, ^{
        s_actions = @{ @(SRGAnalyticsPlayerEventPlay) : @"play",
                       @(SRGAnalyticsPlayerEventPause) : @"pause",
                       @(SRGAnalyticsPlayerEventSeek) : @"seek",
                       @(SRGAnalyticsPlayerEventStop) : @"stop",
                       @(SRGAnalyticsPlayerEventEnd) : @"eof",
                       @(SRGAnalyticsPlayerEventHeartbeat) : @"pos",
                       @(SRGAnalyticsPlayerEventHeartbeat) : @"uptime" };
    });
    
    NSString *action = s_actions[@(event)];
    // Don't send an unknown action
    if (! action) {
        return;
    }
    
    // Don't send an hearbeat events if not playing
    if ((event == SRGAnalyticsPlayerEventHeartbeat || event == SRGAnalyticsPlayerEventLiveHeartbeat) &&
        self.previousPlayerEvent != SRGAnalyticsPlayerEventPlay ) {
        return;
    }
    
    // Don't send a seek event if stop or end before
    if (event == SRGAnalyticsPlayerEventSeek &&
        (self.previousPlayerEvent == SRGAnalyticsPlayerEventStop || self.previousPlayerEvent == SRGAnalyticsPlayerEventEnd)) {
        return;
    }
    
    // If Seeking, try to track pause event before
    if (event == SRGAnalyticsPlayerEventSeek) {
        [self trackTagCommanderPlayerEvent:SRGAnalyticsPlayerEventPause
                                atPosition:position
                                withLabels:labels];
    }
    
    BOOL isASingleEvent = (event == SRGAnalyticsPlayerEventPlay) || (event == SRGAnalyticsPlayerEventPause) || (event == SRGAnalyticsPlayerEventStop) || (event == SRGAnalyticsPlayerEventEnd);
    
    if (isASingleEvent) {
        // Don't send twice the same single event
        if (event == self.previousPlayerEvent) {
            return;
        }
        
        // Don't send pause if not playing before
        if (event == SRGAnalyticsPlayerEventPause && self.previousPlayerEvent != SRGAnalyticsPlayerEventPlay) {
            return;
        }
        
        // Don't send stop if eof before
        if (event == SRGAnalyticsPlayerEventStop && self.previousPlayerEvent == SRGAnalyticsPlayerEventEnd) {
            return;
        }
        
        // Don't send eof if end stop before
        if (event == SRGAnalyticsPlayerEventEnd && self.previousPlayerEvent == SRGAnalyticsPlayerEventStop) {
            return;
        }
        
        self.previousPlayerEvent = event;
    }
    
    // Send the event
    NSMutableDictionary<NSString *, NSString *> *fullLabels = [NSMutableDictionary dictionary];
    [fullLabels srg_safelySetObject:action forKey:@"hit_type"];
    
    [labels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [fullLabels srg_safelySetObject:object forKey:key];
    }];
    
    [[SRGAnalyticsTracker sharedTracker] trackTagCommanderEventWithLabels:[fullLabels copy]];
}

@end
