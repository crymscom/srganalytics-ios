//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGSegment+SRGAnalytics_DataProvider.h"

@implementation SRGSegment (SRGAnalytics_DataProvider)

#pragma mark SRGAnalyticsSegment protocol

- (BOOL)srg_isBlocked
{
    return [self blockingReasonAtDate:[NSDate date]] != SRGBlockingReasonNone;
}

- (BOOL)srg_isHidden
{
    return self.hidden;
}

- (SRGAnalyticsStreamLabels *)srg_analyticsLabels
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.customInfo = self.analyticsLabels;
    labels.comScoreCustomSegmentInfo = self.comScoreAnalyticsLabels;
    return labels;
}

#pragma mark Overrides

- (CMTimeRange)srg_timeRange
{
    return CMTimeRangeMake(CMTimeMakeWithSeconds(self.markIn / 1000., NSEC_PER_SEC),
                           CMTimeMakeWithSeconds(self.duration / 1000., NSEC_PER_SEC));
}

@end
