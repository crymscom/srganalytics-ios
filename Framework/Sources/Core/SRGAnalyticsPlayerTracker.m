//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsPlayerTracker.h"

#import "NSMutableDictionary+SRGAnalytics.h"
#import "SRGAnalyticsTracker+Private.h"

#import <ComScore/ComScore.h>
#import <SRGAnalytics/SRGAnalytics.h>

@interface SRGAnalyticsPlayerTracker ()

@property (nonatomic) CSStreamSense *streamSense;
@property (nonatomic) SRGAnalyticsPlayerEvent previousPlayerEvent;

@end

@implementation SRGAnalyticsPlayerLabels

#pragma mark Getters and setters

- (NSDictionary<NSString *, NSString *> *)labelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary srg_safelySetString:self.playerName forKey:@"media_player_display"];
    [dictionary srg_safelySetString:self.playerVersion forKey:@"media_player_version"];
    [dictionary srg_safelySetString:self.subtitlesEnabled ? @"true" : @"false" forKey:@"media_subtitles_on"];
    [dictionary srg_safelySetString:self.timeshiftInMilliseconds.stringValue forKey:@"media_timeshift_milliseconds"];
    [dictionary srg_safelySetString:self.bandwidthInBitsPerSecond.stringValue forKey:@"media_bandwidth"];
    [dictionary srg_safelySetString:self.volumeInPercent.stringValue forKey:@"media_volume"];
    
    if (self.customInfo) {
        [dictionary addEntriesFromDictionary:self.customInfo];
    }
    
    return [dictionary copy];
}

- (NSDictionary<NSString *, NSString *> *)comScoreLabelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary srg_safelySetString:SRGAnalyticsMarketingVersion() forKey:@"ns_st_pu"];
    [dictionary srg_safelySetString:[SRGAnalyticsTracker sharedTracker].comScoreVirtualSite forKey:@"ns_vsite"];
    [dictionary srg_safelySetString:@"c" forKey:@"ns_st_it"];
    [dictionary srg_safelySetString:@"p_app_ios" forKey:@"srg_ptype"];
    
    [dictionary srg_safelySetString:self.playerName forKey:@"ns_st_mp"];
    [dictionary srg_safelySetString:self.playerVersion forKey:@"ns_st_mv"];
    [dictionary srg_safelySetString:self.bandwidthInBitsPerSecond.stringValue forKey:@"ns_st_br"];
    [dictionary srg_safelySetString:self.volumeInPercent.stringValue ?: @"0" forKey:@"ns_st_vo"];
    
    if (self.comScoreInfo) {
        [dictionary addEntriesFromDictionary:self.comScoreInfo];
    }
    
    return [dictionary copy];
}

- (NSDictionary<NSString *, NSString *> *)comScoreSegmentLabelsDictionary
{
    NSMutableDictionary <NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary srg_safelySetString:self.timeshiftInMilliseconds.stringValue forKey:@"srg_timeshift"];
    
    if (self.comScoreSegmentInfo) {
        [dictionary addEntriesFromDictionary:self.comScoreSegmentInfo];
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
    if (labels.subtitlesEnabled) {
        self.subtitlesEnabled = labels.subtitlesEnabled;
    }
    if (labels.timeshiftInMilliseconds) {
        self.timeshiftInMilliseconds = labels.timeshiftInMilliseconds;
    }
    if (labels.bandwidthInBitsPerSecond) {
        self.bandwidthInBitsPerSecond = labels.bandwidthInBitsPerSecond;
    }
    if (labels.volumeInPercent) {
        self.volumeInPercent = labels.volumeInPercent;
    }
    
    NSMutableDictionary *customInfo = [self.customInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    if (labels.customInfo) {
        [customInfo addEntriesFromDictionary:labels.customInfo];
    }
    self.customInfo = (customInfo.count != 0) ? [customInfo copy] : nil;
    
    NSMutableDictionary *comScoreInfo = [self.comScoreInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    if (labels.comScoreInfo) {
        [comScoreInfo addEntriesFromDictionary:labels.comScoreInfo];
    }
    self.comScoreInfo = (comScoreInfo.count != 0) ? [comScoreInfo copy] : nil;
    
    NSMutableDictionary *comScoreSegmentInfo = [self.comScoreSegmentInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    if (labels.comScoreSegmentInfo) {
        [comScoreSegmentInfo addEntriesFromDictionary:labels.comScoreSegmentInfo];
    }
    self.comScoreSegmentInfo = (comScoreSegmentInfo.count != 0) ? [comScoreSegmentInfo copy] : nil;
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.playerName = self.playerName;
    labels.playerVersion = self.playerVersion;
    labels.subtitlesEnabled = self.subtitlesEnabled;
    labels.timeshiftInMilliseconds = self.timeshiftInMilliseconds;
    labels.bandwidthInBitsPerSecond = self.bandwidthInBitsPerSecond;
    labels.volumeInPercent = self.volumeInPercent;
    labels.customInfo = self.customInfo;
    labels.comScoreInfo = self.comScoreInfo;
    labels.comScoreSegmentInfo = self.comScoreSegmentInfo;
    return labels;
}

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
              withLabels:(SRGAnalyticsPlayerLabels *)labels
{
    [self trackTagCommanderPlayerEvent:event atPosition:position withLabels:labels];
    [self trackComScorePlayerEvent:event atPosition:position withLabels:labels];
}

- (void)trackComScorePlayerEvent:(SRGAnalyticsPlayerEvent)event
                      atPosition:(NSTimeInterval)position
                      withLabels:(SRGAnalyticsPlayerLabels *)labels
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
    [[labels comScoreLabelsDictionary] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [self.streamSense setLabel:key value:object];
    }];
    
    // Reset clip labels to avoid inheriting from a previous segment. This does not reset internal hidden comScore labels
    // (e.g. ns_st_pa), which would otherwise be incorrect
    [[[self.streamSense clip] labels] removeAllObjects];
    [[labels comScoreSegmentLabelsDictionary] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [[self.streamSense clip] setLabel:key value:object];
    }];
    
    [self.streamSense notify:eventType.intValue position:position labels:nil /* already set on the stream and clip objects */];
}

- (void)trackTagCommanderPlayerEvent:(SRGAnalyticsPlayerEvent)event
                          atPosition:(NSTimeInterval)position
                          withLabels:(SRGAnalyticsPlayerLabels *)labels
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_actions;
    static NSDictionary<NSNumber *, NSArray<NSNumber *> *> *s_allowedTransitions;
    static NSArray<NSNumber *> *s_playerSingleHiddenEvents;
    dispatch_once(&s_onceToken, ^{
        s_actions = @{ @(SRGAnalyticsPlayerEventPlay) : @"play",
                       @(SRGAnalyticsPlayerEventPause) : @"pause",
                       @(SRGAnalyticsPlayerEventSeek) : @"seek",
                       @(SRGAnalyticsPlayerEventStop) : @"stop",
                       @(SRGAnalyticsPlayerEventEnd) : @"eof",
                       @(SRGAnalyticsPlayerEventHeartbeat) : @"pos",
                       @(SRGAnalyticsPlayerEventLiveHeartbeat) : @"uptime" };
        
        // Allowed transitions from an event to an other event
        s_allowedTransitions = @{ @(SRGAnalyticsPlayerEventPlay) : @[ @(SRGAnalyticsPlayerEventPause), @(SRGAnalyticsPlayerEventSeek), @(SRGAnalyticsPlayerEventStop), @(SRGAnalyticsPlayerEventEnd), @(SRGAnalyticsPlayerEventHeartbeat), @(SRGAnalyticsPlayerEventLiveHeartbeat) ],
                                  @(SRGAnalyticsPlayerEventPause) : @[ @(SRGAnalyticsPlayerEventPlay), @(SRGAnalyticsPlayerEventSeek), @(SRGAnalyticsPlayerEventStop), @(SRGAnalyticsPlayerEventEnd) ],
                                  @(SRGAnalyticsPlayerEventSeek) : @[ @(SRGAnalyticsPlayerEventPlay), @(SRGAnalyticsPlayerEventPause), @(SRGAnalyticsPlayerEventSeek), @(SRGAnalyticsPlayerEventStop), @(SRGAnalyticsPlayerEventEnd) ],
                                  @(SRGAnalyticsPlayerEventStop) : @[ @(SRGAnalyticsPlayerEventPlay) ],
                                  @(SRGAnalyticsPlayerEventEnd) : @[ @(SRGAnalyticsPlayerEventPlay) ],
                                  @(SRGAnalyticsPlayerEventHeartbeat) : @[ @(SRGAnalyticsPlayerEventPause), @(SRGAnalyticsPlayerEventSeek), @(SRGAnalyticsPlayerEventStop), @(SRGAnalyticsPlayerEventEnd), @(SRGAnalyticsPlayerEventHeartbeat), @(SRGAnalyticsPlayerEventLiveHeartbeat) ],
                                  @(SRGAnalyticsPlayerEventHeartbeat) : @[ @(SRGAnalyticsPlayerEventPause), @(SRGAnalyticsPlayerEventSeek), @(SRGAnalyticsPlayerEventStop), @(SRGAnalyticsPlayerEventEnd), @(SRGAnalyticsPlayerEventHeartbeat), @(SRGAnalyticsPlayerEventLiveHeartbeat) ] };
        
        // Don't send twice a player single event
        s_playerSingleHiddenEvents = @[ @(SRGAnalyticsPlayerEventPlay), @(SRGAnalyticsPlayerEventPause), @(SRGAnalyticsPlayerEventSeek), @(SRGAnalyticsPlayerEventStop), @(SRGAnalyticsPlayerEventEnd) ];

    });
    
    NSString *action = s_actions[@(event)];
    // Don't send an unknown action
    if (! action) {
        return;
    }
    
    // Don't send an unallowed action
    NSArray<NSNumber *> *allowTransitions = s_allowedTransitions[@(self.previousPlayerEvent)];
    if (! [allowTransitions containsObject:@(event)]) {
        return;
    }
    
    if ([s_playerSingleHiddenEvents containsObject:@(event)]) {
        self.previousPlayerEvent = event;
    }
    
    // Send the event
    NSMutableDictionary<NSString *, NSString *> *fullLabelsDictionary = [NSMutableDictionary dictionary];
    [fullLabelsDictionary srg_safelySetString:action forKey:@"event_id"];
    [fullLabelsDictionary srg_safelySetString:@(position).stringValue forKey:@"media_position"];
    
    NSDictionary<NSString *, NSString *> *labelsDictionary = [labels labelsDictionary];
    [labelsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull object, BOOL * _Nonnull stop) {
        [fullLabelsDictionary srg_safelySetString:object forKey:key];
    }];
    
    [[SRGAnalyticsTracker sharedTracker] trackTagCommanderEventWithLabels:[fullLabelsDictionary copy]];
}

@end
