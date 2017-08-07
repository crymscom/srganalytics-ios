//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGAnalyticsConfiguration (Private)

/**
 *  The heartbeat interval which will be applied.
 */
@property (nonatomic, readonly) NSTimeInterval heartbeatInterval;

@end

NS_ASSUME_NONNULL_END
