//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSAnalyticsVersion_private.h"

NSString * const RTSAnalyticsVersion(void)
{
#ifdef RTS_ANALYTICS_VERSION
    return @(OS_STRINGIFY(RTS_ANALYTICS_VERSION));
#else
    #warning No explicit version has been specified, set to "dev". Compile the project with a preprocessor macro called RTS_ANALYTICS_VERSION supplying the version number (without quotes)
    return @"dev";
#endif
}
