//
//  Created by Samuel Défago on 12/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "Segment.h"

@interface Segment ()

@property (nonatomic) CMTimeRange timeRange;

@end

@implementation Segment

#pragma mark - Object lifecycle

- (instancetype) initWithTimeRange:(CMTimeRange)timeRange
{
    if (self = [super init])
    {
        self.timeRange = timeRange;
        
    }
    return self;
}

#pragma mark - RTSMediaSegment protocol

- (BOOL)isBlocked
{
    return NO;
}

- (BOOL)isVisible
{
    return YES;
}

@end
