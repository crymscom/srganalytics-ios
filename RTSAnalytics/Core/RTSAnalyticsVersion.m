//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSAnalyticsVersion_private.h"

NSString * const RTSAnalyticsVersion(void)
{
#ifdef RTS_ANALYTICS_VERSION
    return @(OS_STRINGIFY(RTS_ANALYTICS_VERSION));
#else
    return @"dev";
#endif
}
