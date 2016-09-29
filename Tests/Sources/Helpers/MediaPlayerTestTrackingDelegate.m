//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerTestTrackingDelegate.h"

#import "Segment.h"

@interface MediaPlayerTestTrackingDelegate ()

@property (nonatomic, copy) NSString *name;

@end

@implementation MediaPlayerTestTrackingDelegate

- (instancetype)initWithName:(NSString *)name
{
    if (self = [super init]) {
        self.name = name;
    }
    return self;
}

- (NSDictionary<NSString *,NSString *> *)contentLabels
{
    return @{ @"stream_name" : self.name,
              @"overridable_name" : self.name };
}

- (NSDictionary<NSString *,NSString *> *)labelsForSegment:(Segment *)segment
{
    if (segment) {
        return @{ @"segment_name" : segment.name,
                  @"overridable_name" : segment.name };
        
    }
    else {
        return nil;
    }
}

@end
