//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalytics.h"

#import "NSBundle+SRGAnalytics.h"

#if __has_include(<SRGContentProtection/SRGContentProtection.h>)
#import <SRGContentProtection/SRGContentProtection.h>
#endif

NSString *SRGAnalyticsMarketingVersion(void)
{
    return [NSBundle srg_analyticsBundle].infoDictionary[@"CFBundleShortVersionString"];
}

BOOL SRGAnalyticsIsPublic(void)
{
#if __has_include(<SRGContentProtection/SRGContentProtection.h>)
    return (&SRGContentProtectionIsPublic != NULL) ? SRGContentProtectionIsPublic() : YES;
#else
    return YES;
#endif
}
