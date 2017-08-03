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

- (SRGAnalyticsPlayerLabels *)srg_analyticsLabels
{
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customValues = @{ @"segment_name" : self.name,
                             @"overridable_name" : self.name };
    return labels;
}

- (NSDictionary<NSString *,NSString *> *)srg_comScoreAnalyticsLabels
{
    return @{ @"segment_name" : self.name,
              @"overridable_name" : self.name };
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
