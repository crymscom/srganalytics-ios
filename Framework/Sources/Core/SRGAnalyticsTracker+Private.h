//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Private interface for implementation purposes
 */
@interface SRGAnalyticsTracker (Private)

/**
 *  Track a page view
 *
 *  @param title                The page title
 *  @param levels               An array of levels in increasing order, describing the position of the view in the hierarchy
 *  @param customLabels         Additional custom labels
 *  @param fromPushNotification YES iff the view is opened from a push notification
 */
- (void)trackPageViewTitle:(NSString *)title levels:(nullable NSArray<NSString *> *)levels customLabels:(nullable NSDictionary<NSString *, NSString *> *)customLabels fromPushNotification:(BOOL)fromPushNotification;

@end

NS_ASSUME_NONNULL_END
