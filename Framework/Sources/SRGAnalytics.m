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

@implementation NSBundle (SRGAnalyticsVersion)

+ (BOOL)srg_analyticsIsPublic
{
#if __has_include(<SRGContentProtection/SRGContentProtection.h>)
    if ([[NSBundle class] respondsToSelector:@selector(srg_contentProtectionIsPublic)]) {
        return [NSBundle srg_contentProtectionIsPublic];
    }
    else {
        return YES;
    }
#else
    return YES;
#endif
}

@end

