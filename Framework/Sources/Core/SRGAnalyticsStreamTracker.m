//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsStreamTracker.h"

#import "SRGComScoreStreamTracker.h"
#import "SRGTagCommanderStreamTracker.h"

@interface SRGAnalyticsStreamTracker ()

@property (nonatomic) SRGTagCommanderStreamTracker *tagCommanderTracker;
@property (nonatomic) SRGComScoreStreamTracker *comScoreTracker;

@end

@implementation SRGAnalyticsStreamTracker

#pragma mark Object lifecycle

- (instancetype)initWithStreamType:(SRGAnalyticsStreamType)streamType delegate:(id<SRGAnalyticsStreamTrackerDelegate>)delegate
{
    if (self = [super init]) {
        self.tagCommanderTracker = [[SRGTagCommanderStreamTracker alloc] initWithStreamType:streamType delegate:delegate];
        self.comScoreTracker = [[SRGComScoreStreamTracker alloc] initWithStreamType:streamType delegate:delegate];
    }
    return self;
}

#pragma mark Tracking

- (void)updateWithStreamState:(SRGAnalyticsStreamState)state
                     position:(NSTimeInterval)position
                       labels:(SRGAnalyticsStreamLabels *)labels;
{
    [self.tagCommanderTracker updateWithStreamState:state position:position labels:labels];
    [self.comScoreTracker updateWithStreamState:state position:position labels:labels];
}

@end
