//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGSegment+SRGAnalytics_DataProvider.h"

@implementation SRGSegment (SRGAnalytics_DataProvider)

#pragma mark SRGAnalyticsSegment protocol

- (CMTimeRange)srg_timeRange
{
    return CMTimeRangeMake(CMTimeMakeWithSeconds(self.markIn / 1000., NSEC_PER_SEC),
                           CMTimeMakeWithSeconds(self.duration / 1000., NSEC_PER_SEC));
}

- (BOOL)srg_isBlocked
{
    return self.blockingReason != SRGBlockingReasonNone;
}

- (BOOL)srg_isHidden
{
    return self.hidden;
}

- (NSDictionary<NSString *,NSString *> *)srg_comScoreLabels
{
    return self.analyticsLabels;
}

- (NSDictionary<NSString *,NSString *> *)srg_analyticsLabels
{
    if (self.analyticsLabels[@"ns_st_ep"]) {
        return  @{@"VIDEO_SEGMENT" : self.analyticsLabels[@"ns_st_ep"] };
    }
    else {
        return nil;
    }
}

@end
