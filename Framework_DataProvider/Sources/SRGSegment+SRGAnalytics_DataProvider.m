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
    return CMTimeRangeMake(CMTimeMakeWithSeconds(self.markIn, NSEC_PER_SEC),
                           CMTimeMakeWithSeconds(self.markOut, NSEC_PER_SEC));
}

- (BOOL)srg_isBlocked
{
    return self.blockingReason != SRGBlockingReasonNone;
}

- (BOOL)srg_isHidden
{
    return NO;
}

- (NSDictionary<NSString *,NSString *> *)srg_analyticsLabels
{
    // TODO: Consolidate with information on media composition and parent chapter. Probably
    //       a data provider issue: When parsing data, high-level data needs to be merged into
    //       chapter data. Maybe have a weak pointer to the parent
    return self.analyticsLabels;
}

@end
