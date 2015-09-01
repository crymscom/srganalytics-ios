//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "Segment.h"

@interface Segment ()

@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, getter=isBlocked) BOOL blocked;

@end

@implementation Segment

#pragma mark - Object lifecycle

- (instancetype) initWithTimeRange:(CMTimeRange)timeRange name:(NSString *)name blocked:(BOOL)blocked
{
    if (self = [super init])
    {
        self.timeRange = timeRange;
        self.name = name;
        self.blocked = blocked;
    }
    return self;
}

#pragma mark - RTSMediaSegment protocol

- (BOOL)isVisible
{
    return YES;
}

@end
