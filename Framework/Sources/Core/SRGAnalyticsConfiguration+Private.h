//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGAnalyticsConfiguration (Private)

/**
 *  The TagCommand site which will be used.
 */
@property (nonatomic, readonly) NSInteger site;

/**
 *  The NetMetrix domain.
 */
@property (nonatomic, readonly, copy, nullable) NSString *netMetrixDomain;

@end

NS_ASSUME_NONNULL_END
