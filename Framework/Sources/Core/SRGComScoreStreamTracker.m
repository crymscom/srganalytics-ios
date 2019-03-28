//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGComScoreStreamTracker.h"

@implementation SRGComScoreStreamTracker

- (instancetype)initWithStreamType:(SRGAnalyticsStreamType)streamType delegate:(id<SRGAnalyticsStreamTrackerDelegate>)delegate
{
    if (self = [super init]) {
        
    }
    return self;
}

- (void)updateWithStreamState:(SRGAnalyticsStreamState)state
                     position:(NSTimeInterval)position
                       labels:(SRGAnalyticsStreamLabels *)labels
{
    
}

@end
