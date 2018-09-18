//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalytics.h"

#import "NSBundle+SRGAnalytics.h"

// Default implementation if not linking against SRGContentProtection.framework
FOUNDATION_EXPORT BOOL SRGContentProtectionIsPublic(void)
{
    return YES;
}

NSString *SRGAnalyticsMarketingVersion(void)
{
    return [NSBundle srg_analyticsBundle].infoDictionary[@"CFBundleShortVersionString"];
}

BOOL SRGAnalyticsIsPublic(void)
{
    return (&SRGContentProtectionIsPublic != NULL) ? SRGContentProtectionIsPublic() : YES;
}
