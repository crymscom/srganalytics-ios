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

- (SRGAnalyticsPlayerLabels *)srg_analyticsLabels
{
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = self.analyticsLabels;
    labels.comScoreCustomSegmentInfo = self.comScoreAnalyticsLabels;
    return labels;
}

@end
