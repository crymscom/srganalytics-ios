//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalytics.h"

#import "NSBundle+SRGAnalytics.h"

NSString *SRGAnalyticsMarketingVersion(void)
{
    return [NSBundle srg_analyticsBundle].infoDictionary[@"CFBundleShortVersionString"];
}
