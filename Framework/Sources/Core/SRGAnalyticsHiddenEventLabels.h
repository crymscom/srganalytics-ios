//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsLabels.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Additional hidden event labels.
 */
@interface SRGAnalyticsHiddenEventLabels : SRGAnalyticsLabels

/**
 *  The event type (this concept is loosely defined, please discuss expected values for your application with your
 *  measurement team).
 */
@property (nonatomic, copy, nullable) NSString *type;

/**
 *  The event value (this concept is loosely defined, please discuss expected values for your application with your
 *  measurement team).
 */
@property (nonatomic, copy, nullable) NSString *value;

/**
 *  The event source (this concept is loosely defined, please discuss expected values for your application with your
 *  measurement team).
 */
@property (nonatomic, copy, nullable) NSString *source;

@end

NS_ASSUME_NONNULL_END
