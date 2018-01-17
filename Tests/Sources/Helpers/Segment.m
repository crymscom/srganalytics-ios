//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

@interface Segment ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic) CMTimeRange srg_timeRange;
@property (nonatomic, getter=srg_isBlocked) BOOL srg_blocked;

@end

@implementation Segment

#pragma mark Class methods

+ (Segment *)segmentWithName:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    return [[[self class] alloc] initWithName:name timeRange:timeRange];
}

+ (Segment *)blockedSegmentWithName:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    Segment *segment = [[[self class] alloc] initWithName:name timeRange:timeRange];
    segment.srg_blocked = YES;
    return segment;
}

#pragma mark Object lifecycle

- (instancetype)initWithName:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    if (self = [super init]) {
        self.name = name;
        self.srg_timeRange = timeRange;
    }
    return self;
}

#pragma mark Getters and setters

- (BOOL)srg_isHidden
{
    // NO need to test hidden segments in unit tests, those are only for use by UI overlays
    return NO;
}

#pragma mark SRGAnalyticsSegment protocol

- (SRGAnalyticsStreamLabels *)srg_analyticsLabels
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.customInfo = @{ @"segment_name" : self.name,
                           @"overridable_name" : self.name };
    labels.comScoreCustomInfo = @{ @"segment_name" : self.name,
                               @"overridable_name" : self.name };
    return labels;
}

#pragma mark Equality

- (BOOL)isEqual:(id)object
{
    if (! object || ! [object isKindOfClass:[self class]]) {
        return NO;
    }
    
    Segment *otherSegment = object;
    return [self.name isEqual:otherSegment.name] && CMTimeRangeEqual(self.srg_timeRange, otherSegment.srg_timeRange) && self.srg_blocked == otherSegment.srg_blocked;
}

- (NSUInteger)hash
{
    return [NSString stringWithFormat:@"%@_%@_%@_%@", @(self.name.hash), @(CMTimeGetSeconds(self.srg_timeRange.start)), @(CMTimeGetSeconds(self.srg_timeRange.duration)), @(self.srg_blocked)].hash;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; name: %@; startTime: %@; duration: %@>",
            [self class],
            self,
            self.name,
            @(CMTimeGetSeconds(self.srg_timeRange.start)),
            @(CMTimeGetSeconds(self.srg_timeRange.duration))];
}

@end
