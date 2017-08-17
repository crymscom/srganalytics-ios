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
@property (nonatomic) SRGAnalyticsPlayerEvent previousPlayerEvent;

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

- (void)updateWithPlayerEvent:(SRGAnalyticsPlayerEvent)event
                     position:(NSTimeInterval)position
                       labels:(SRGAnalyticsPlayerLabels *)labels
{
    [self updateTagCommanderWithPlayerEvent:event position:position labels:labels];
    [self updateComScoreWithPlayerEvent:event position:position labels:labels];
}

- (void)updateComScoreWithPlayerEvent:(SRGAnalyticsPlayerEvent)event
                             position:(NSTimeInterval)position
                               labels:(SRGAnalyticsPlayerLabels *)labels
{
    // Ensure a play is emitted before events requiring a session to be opened (the comScore SDK does not open sessions
    // automatically)
    if (! self.comScoreSessionAlive && (event == SRGAnalyticsPlayerEventPause || event == SRGAnalyticsPlayerEventSeek)) {
        [self updateComScoreWithPlayerEvent:SRGAnalyticsPlayerEventPlay position:position labels:labels];
    }
    
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
    
    NSNumber *eventTypeValue = s_streamSenseEvents[@(event)];
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
    
    CSStreamSenseEventType eventType = eventTypeValue.intValue;
    [self.streamSense notify:eventType position:position labels:nil /* already set on the stream and clip objects */];
    
    if (eventType == CSStreamSensePlay) {
        self.comScoreSessionAlive = YES;
    }
    else if (eventType == CSStreamSenseEnd) {
        self.comScoreSessionAlive = NO;
    }
}

- (void)updateTagCommanderWithPlayerEvent:(SRGAnalyticsPlayerEvent)event
                                 position:(NSTimeInterval)position
                                   labels:(SRGAnalyticsPlayerLabels *)labels
{
    // Ensure a play is emitted before events requiring a session to be opened (the TagCommander SDK does not open sessions
    // automatically)
    if (self.previousPlayerEvent == SRGAnalyticsPlayerEventEnd && (event == SRGAnalyticsPlayerEventPause || event == SRGAnalyticsPlayerEventSeek)) {
        [self updateTagCommanderWithPlayerEvent:SRGAnalyticsPlayerEventPlay position:position labels:labels];
    }
    
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
                                  @(SRGAnalyticsPlayerEventSeek) : @[ @(SRGAnalyticsPlayerEventPlay), @(SRGAnalyticsPlayerEventPause), @(SRGAnalyticsPlayerEventStop), @(SRGAnalyticsPlayerEventEnd) ],
                                  @(SRGAnalyticsPlayerEventStop) : @[ @(SRGAnalyticsPlayerEventPlay) ],
                                  @(SRGAnalyticsPlayerEventEnd) : @[ @(SRGAnalyticsPlayerEventPlay) ],
                                  @(SRGAnalyticsPlayerEventHeartbeat) : @[ @(SRGAnalyticsPlayerEventPause), @(SRGAnalyticsPlayerEventSeek), @(SRGAnalyticsPlayerEventStop), @(SRGAnalyticsPlayerEventEnd), @(SRGAnalyticsPlayerEventHeartbeat), @(SRGAnalyticsPlayerEventLiveHeartbeat) ],
                                  @(SRGAnalyticsPlayerEventLiveHeartbeat) : @[ @(SRGAnalyticsPlayerEventPause), @(SRGAnalyticsPlayerEventSeek), @(SRGAnalyticsPlayerEventStop), @(SRGAnalyticsPlayerEventEnd), @(SRGAnalyticsPlayerEventHeartbeat), @(SRGAnalyticsPlayerEventLiveHeartbeat) ] };
        
        // Don't send twice a player single event
        s_playerSingleHiddenEvents = @[ @(SRGAnalyticsPlayerEventPlay), @(SRGAnalyticsPlayerEventPause), @(SRGAnalyticsPlayerEventSeek), @(SRGAnalyticsPlayerEventStop), @(SRGAnalyticsPlayerEventEnd) ];
    });
    
    NSString *action = s_actions[@(event)];
    // Don't send an unknown action
    if (! action) {
        return;
    }
    
    // Don't send an unallowed action
    if (! [s_allowedTransitions[@(self.previousPlayerEvent)] containsObject:@(event)]) {
        return;
    }
    
    if ([s_playerSingleHiddenEvents containsObject:@(event)]) {
        self.previousPlayerEvent = event;
    }
    
    // Send the event
    NSMutableDictionary<NSString *, NSString *> *fullLabelsDictionary = [NSMutableDictionary dictionary];
    [fullLabelsDictionary srg_safelySetString:action forKey:@"event_id"];
    [fullLabelsDictionary srg_safelySetString:@(round(position / 1000)).stringValue forKey:@"media_position"];
    
    NSDictionary<NSString *, NSString *> *labelsDictionary = [labels labelsDictionary];
    if (labelsDictionary) {
        [fullLabelsDictionary addEntriesFromDictionary:labelsDictionary];
    }
    
    [[SRGAnalyticsTracker sharedTracker] trackTagCommanderEventWithLabels:[fullLabelsDictionary copy]];
}

@end
