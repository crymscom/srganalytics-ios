//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGSubdivision+SRGAnalytics_DataProvider.h"

@implementation SRGSubdivision (SRGAnalytics_DataProvider)

- (CMTimeRange)srg_timeRange
{
    return CMTimeRangeMake(CMTimeMakeWithSeconds(0., NSEC_PER_SEC),
                           CMTimeMakeWithSeconds(self.duration / 1000., NSEC_PER_SEC));
}

@end
