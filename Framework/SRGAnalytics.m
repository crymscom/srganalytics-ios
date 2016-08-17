//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalytics.h"

#import "NSBundle+RTSAnalytics.h"

NSString * SRGAnalyticsMarketingVersion(void)
{
    return [NSBundle RTSAnalyticsBundle].infoDictionary[@"CFBundleVersion"];
}
