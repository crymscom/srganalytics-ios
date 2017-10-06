//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsStreamLabels.h"

#import "NSBundle+SRGAnalytics.h"
#import "NSMutableDictionary+SRGAnalytics.h"

@implementation SRGAnalyticsStreamLabels

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
    
    [dictionary addEntriesFromDictionary:[super labelsDictionary]];
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
    
    [dictionary addEntriesFromDictionary:[super comScoreLabelsDictionary]];
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

- (void)mergeWithLabels:(SRGAnalyticsStreamLabels *)labels
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
    SRGAnalyticsStreamLabels *labels = [super copyWithZone:zone];
    labels.playerName = self.playerName;
    labels.playerVersion = self.playerVersion;
    labels.playerVolumeInPercent = self.playerVolumeInPercent;
    labels.subtitlesEnabled = self.subtitlesEnabled;
    labels.timeshiftInMilliseconds = self.timeshiftInMilliseconds;
    labels.bandwidthInBitsPerSecond = self.bandwidthInBitsPerSecond;
    labels.comScoreCustomSegmentInfo = self.comScoreCustomSegmentInfo;
    return labels;
}

@end
