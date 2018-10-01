//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsHiddenEventLabels.h"

#import "NSMutableDictionary+SRGAnalytics.h"

@implementation SRGAnalyticsHiddenEventLabels

#pragma mark Getters and setters

- (NSDictionary<NSString *, NSString *> *)labelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary srg_safelySetString:self.type forKey:@"event_type"];
    [dictionary srg_safelySetString:self.value forKey:@"event_value"];
    [dictionary srg_safelySetString:self.source forKey:@"event_source"];
    
    NSUInteger valueIndex = 1;
    for (NSString *value in self.values) {
        [dictionary srg_safelySetString:value forKey:[NSString stringWithFormat:@"event_value_%lu", valueIndex]];
        valueIndex++;
    }
    
    [dictionary addEntriesFromDictionary:[super labelsDictionary]];
    return [dictionary copy];
}

- (NSDictionary<NSString *, NSString *> *)comScoreLabelsDictionary
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary srg_safelySetString:self.type forKey:@"srg_evgroup"];
    [dictionary srg_safelySetString:self.value forKey:@"srg_evvalue"];
    [dictionary srg_safelySetString:self.source forKey:@"srg_evsource"];
    
    [dictionary addEntriesFromDictionary:[super comScoreLabelsDictionary]];
    return [dictionary copy];
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    SRGAnalyticsHiddenEventLabels *labels = [super copyWithZone:zone];
    labels.type = self.type;
    labels.value = self.value;
    labels.values = self.values.copy;
    labels.source = self.source;
    return labels;
}

@end
