//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGSegment+SRGAnalytics_DataProvider.h"

@implementation SRGSegment (SRGAnalytics_DataProvider)

#pragma mark Overrides

- (SRGAnalyticsPlayerLabels *)srg_analyticsLabels
{
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = self.analyticsLabels;
    labels.comScoreCustomSegmentInfo = self.comScoreAnalyticsLabels;        // Stored in segment info
    return labels;
}

@end
