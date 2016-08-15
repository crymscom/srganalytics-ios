//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

@interface Segment ()

@property (nonatomic, copy) NSString *segmentIdentifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) CMTimeRange timeRange;

@end

@implementation Segment

- (instancetype)initWithIdentifier:(NSString *)identifier name:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    if (self = [super init]) {
        self.name = name;
        self.segmentIdentifier = identifier;
        self.timeRange = timeRange;
        self.visible = YES;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; name: %@; segmentIdentifier: %@; start: %@; duration: %@>",
            [self class],
            self,
            self.name,
            self.segmentIdentifier,
            @(CMTimeGetSeconds(self.timeRange.start)).stringValue,
            @(CMTimeGetSeconds(self.timeRange.duration)).stringValue];
}

@end
