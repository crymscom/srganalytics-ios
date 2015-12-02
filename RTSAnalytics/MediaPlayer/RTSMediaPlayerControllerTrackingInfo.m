//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerControllerTrackingInfo.h"

@implementation RTSMediaPlayerControllerTrackingInfo

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    RTSMediaPlayerControllerTrackingInfo *copy = [[RTSMediaPlayerControllerTrackingInfo alloc] init];
    copy.segment = self.segment;
    copy.customLabels = self.customLabels;
    copy.skippingNextEvents = self.skippingNextEvents;
    return copy;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; segment: %@; customLabels: %@; skippingNextEvents: %@>",
            [self class],
            self,
            self.segment,
            self.customLabels,
            self.skippingNextEvents ? @"YES" : @"NO"];
}

@end
